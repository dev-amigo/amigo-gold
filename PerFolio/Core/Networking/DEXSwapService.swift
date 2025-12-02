import Foundation
import PrivySDK
import Combine
import CryptoKit

/// DEX swap service for bi-directional USDC ↔ PAXG conversion
/// Uses 0x Aggregator for quotes and transaction data
/// Executes swaps via Privy REST API with gas sponsorship (sponsor: true)
/// Aligned with Web implementation: retry logic, receipt polling, transaction recovery
final class DEXSwapService: ObservableObject {
    
    // MARK: - Types
    
    struct SwapQuote {
        let fromToken: Token
        let toToken: Token
        let fromAmount: Decimal
        let toAmount: Decimal
        let estimatedGas: String
        let priceImpact: Decimal
        let route: String
        let exchangeRate: Decimal  // Added: Rate for display (like web)
        
        var displayFromAmount: String {
            CurrencyFormatter.formatToken(fromAmount, symbol: fromToken.symbol)
        }
        
        var displayToAmount: String {
            CurrencyFormatter.formatToken(toAmount, symbol: toToken.symbol, maxDecimals: 8)
        }
        
        var displayPriceImpact: String {
            "\(CurrencyFormatter.formatDecimal(priceImpact))%"
        }
        
        var isPriceImpactHigh: Bool {
            priceImpact > ServiceConstants.highPriceImpactThreshold
        }
        
        /// Display exchange rate (like web: "1 USDC = X PAXG")
        var displayExchangeRate: String {
            let decimals = fromToken.symbol == "USDC" ? 6 : 2
            return "1 \(fromToken.symbol) = \(CurrencyFormatter.formatDecimal(exchangeRate, maxDecimals: decimals)) \(toToken.symbol)"
        }
        
        /// Convert estimated gas string to Decimal (e.g., "~$5-10" → 7.5)
        var estimatedGasDecimal: Decimal {
            // Parse "~$5-10" → average of 5 and 10 = 7.5
            let cleaned = estimatedGas.replacingOccurrences(of: "~$", with: "").replacingOccurrences(of: "$", with: "")
            let parts = cleaned.split(separator: "-").map { String($0).trimmingCharacters(in: .whitespaces) }
            
            if parts.count == 2,
               let min = Decimal(string: parts[0]),
               let max = Decimal(string: parts[1]) {
                return (min + max) / 2
            } else if let value = Decimal(string: cleaned) {
                return value
            }
            
            return 7.5  // Default fallback
        }
    }
    
    struct Token: Equatable {
        let address: String
        let symbol: String
        let decimals: Int
        let name: String
        
        static let usdc = Token(
            address: ContractAddresses.usdc,
            symbol: "USDC",
            decimals: 6,
            name: "USD Coin"
        )
        
        static let paxg = Token(
            address: ContractAddresses.paxg,
            symbol: "PAXG",
            decimals: 18,
            name: "Paxos Gold"
        )
        
        /// Get minimum swap amount for this token (like web has for USDC)
        var minimumSwapAmount: Decimal {
            switch symbol {
            case "USDC": return 10.0      // $10 minimum
            case "PAXG": return 0.004     // ~$10 worth at ~$2500/oz
            default: return 10.0
            }
        }
    }
    
    struct SwapParams {
        let fromToken: Token
        let toToken: Token
        let amount: Decimal
        let slippageTolerance: Decimal // e.g., 0.5 for 0.5%
        let fromAddress: String
    }
    
    /// Transaction result with recovery info (aligned with web)
    struct TransactionResult {
        let success: Bool
        let possibleSuccess: Bool  // Transaction may have succeeded but confirmation unclear
        let txHash: String?
        let error: SwapError?
        let receipt: TransactionReceipt?
    }
    
    /// Transaction receipt from eth_getTransactionReceipt
    struct TransactionReceipt {
        let transactionHash: String
        let status: Bool  // true = success, false = reverted
        let blockNumber: String
        let gasUsed: String
    }
    
    private struct ZeroExQuoteResponse: Decodable {
        struct Source: Decodable {
            let name: String
            let proportion: String
        }
        
        let price: String
        let guaranteedPrice: String?
        let buyAmount: String
        let sellAmount: String
        let to: String
        let data: String
        let value: String
        let gas: String?
        let estimatedGas: String?
        let gasPrice: String?
        let allowanceTarget: String
        let sources: [Source]?
    }
    
    enum SwapError: LocalizedError {
        case insufficientBalance(token: String)
        case insufficientLiquidity
        case slippageTooHigh
        case approvalRequired
        case networkError(String)
        case invalidAmount
        case transactionFailed(String)
        case transactionTimeout
        case userRejected
        
        var errorDescription: String? {
            switch self {
            case .insufficientBalance(let token):
                return "Insufficient \(token) balance"
            case .insufficientLiquidity:
                return "Insufficient liquidity for this swap"
            case .slippageTooHigh:
                return "Price impact is too high. Try a smaller amount."
            case .approvalRequired:
                return "Token approval required before swap"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidAmount:
                return "Please enter a valid amount"
            case .transactionFailed(let reason):
                return "Transaction failed: \(reason)"
            case .transactionTimeout:
                return "Transaction may have succeeded. Please check your wallet activity on Etherscan."
            case .userRejected:
                return "Transaction was rejected by user"
            }
        }
    }
    
    enum ApprovalState {
        case notRequired
        case required
        case pending
        case approved
    }
    
    /// Transaction status (aligned with web TransactionStatus)
    enum TransactionStatus {
        case idle
        case approving
        case swapping
        case success
        case failed
    }
    
    // MARK: - Properties
    
    private let web3Client: Web3Client
    private let erc20Contract: ERC20Contract
    
    @Published var isLoading = false
    @Published var currentQuote: SwapQuote?
    @Published var approvalState: ApprovalState = .notRequired
    @Published var transactionStatus: TransactionStatus = .idle  // Added: Track tx status like web
    @Published var lastTxHash: String?  // Added: Store last tx hash like web
    
    // 0x API configuration
    private let zeroExQuoteURL = "https://api.0x.org/swap/v1/quote"
    private var latestZeroExQuote: ZeroExQuoteResponse?
    private let zeroExAPIKey: String
    
    // Slippage tolerance (0.5% default)
    let defaultSlippageTolerance = ServiceConstants.defaultSlippageTolerance
    
    // Retry configuration (aligned with web)
    private let maxRetries = 3
    private let retryDelayMs: UInt64 = 1_000_000_000  // 1 second
    
    // Transaction confirmation configuration
    private let maxConfirmationAttempts = 30  // 30 attempts
    private let confirmationPollIntervalMs: UInt64 = 2_000_000_000  // 2 seconds per poll = 60s max
    
    // MARK: - Initialization
    
    init(
        web3Client: Web3Client = Web3Client(),
        erc20Contract: ERC20Contract = ERC20Contract()
    ) {
        self.web3Client = web3Client
        self.erc20Contract = erc20Contract
        self.zeroExAPIKey = Bundle.main.object(forInfoDictionaryKey: "AGZeroXAPIKey") as? String ?? ""
        
        AppLogger.log("🔄 DEXSwapService initialized (bi-directional swap support)", category: "dex")
        AppLogger.log("   0x Quote URL: \(zeroExQuoteURL)", category: "dex")
        AppLogger.log("   Retry config: \(maxRetries) attempts, \(retryDelayMs/1_000_000)ms delay", category: "dex")
    }
    
    // MARK: - Public Methods
    
    /// Get swap quote for bi-directional swap (USDC ↔ PAXG)
    /// Aligned with web: includes retry logic and proper error handling
    func getQuote(params: SwapParams) async throws -> SwapQuote {
        AppLogger.log("📊 Getting swap quote: \(params.amount) \(params.fromToken.symbol) → \(params.toToken.symbol)", category: "dex")
        
        guard params.amount > 0 else {
            throw SwapError.invalidAmount
        }
        
        // Dynamic minimum amount based on token (aligned with web approach)
        let minimumSwapAmount = params.fromToken.minimumSwapAmount
        guard params.amount >= minimumSwapAmount else {
            AppLogger.log("❌ Amount too small: \(params.amount) \(params.fromToken.symbol) (minimum: \(minimumSwapAmount))", category: "dex")
            throw SwapError.networkError("Minimum swap amount is \(minimumSwapAmount) \(params.fromToken.symbol). Please enter a larger amount.")
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Check balance for the FROM token (bi-directional support)
        let erc20Token: ERC20Contract.Token = params.fromToken.symbol == "USDC" ? .usdc : .paxg
        let balances = try await erc20Contract.balancesOf(
            tokens: [erc20Token],
            address: params.fromAddress
        )
        
        guard let balance = balances.first, balance.decimalBalance >= params.amount else {
            throw SwapError.insufficientBalance(token: params.fromToken.symbol)
        }
        
        // Use retry logic (aligned with web fetchWithRetry)
        return try await fetchQuoteWithRetry(params: params, retriesLeft: maxRetries)
    }
    
    /// Fetch quote with retry logic (aligned with web implementation)
    private func fetchQuoteWithRetry(params: SwapParams, retriesLeft: Int) async throws -> SwapQuote {
        let sellAmount = try toBaseUnits(params.amount, decimals: params.fromToken.decimals)
        var components = URLComponents(string: zeroExQuoteURL)
        components?.queryItems = [
            URLQueryItem(name: "sellToken", value: params.fromToken.address),
            URLQueryItem(name: "buyToken", value: params.toToken.address),
            URLQueryItem(name: "sellAmount", value: sellAmount),
            URLQueryItem(name: "takerAddress", value: params.fromAddress),
            URLQueryItem(
                name: "slippagePercentage",
                value: NSDecimalNumber(decimal: params.slippageTolerance / 100).stringValue
            )
        ]
        
        guard let url = components?.url else {
            throw SwapError.networkError("Invalid 0x quote URL")
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30  // 30 second timeout
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if !zeroExAPIKey.isEmpty {
            request.addValue(zeroExAPIKey, forHTTPHeaderField: "0x-api-key")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw SwapError.networkError("0x quote failed: \(message)")
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let quoteResponse = try decoder.decode(ZeroExQuoteResponse.self, from: data)
            latestZeroExQuote = quoteResponse
            
            let toAmount = fromBaseUnits(quoteResponse.buyAmount, decimals: params.toToken.decimals)
            let estimatedGasValue = decimalFromString(quoteResponse.estimatedGas ?? quoteResponse.gas ?? "")
            let estimatedGasText = estimatedGasValue != nil ? "~\(estimatedGasValue!) gas" : ServiceConstants.estimatedGasCost
            let activeSources = quoteResponse.sources?.filter {
                decimalFromString($0.proportion) ?? 0 > 0
            }.map { $0.name } ?? []
            let route = activeSources.isEmpty ? "0x Aggregator" : activeSources.joined(separator: " → ")
            
            // Calculate exchange rate (aligned with web calculateRate)
            let exchangeRate: Decimal
            if params.amount > 0 {
                exchangeRate = toAmount / params.amount
            } else {
                exchangeRate = 0
            }
            
            let quote = SwapQuote(
                fromToken: params.fromToken,
                toToken: params.toToken,
                fromAmount: params.amount,
                toAmount: toAmount,
                estimatedGas: estimatedGasText,
                priceImpact: 0.1,
                route: route,
                exchangeRate: exchangeRate
            )
            
            currentQuote = quote
            AppLogger.log("✅ Quote: \(quote.displayFromAmount) → \(quote.displayToAmount)", category: "dex")
            AppLogger.log("   Route: \(quote.route)", category: "dex")
            AppLogger.log("   Exchange Rate: \(quote.displayExchangeRate)", category: "dex")
            return quote
            
        } catch let error as SwapError {
            throw error
        } catch {
            // Retry logic for network errors (aligned with web)
            let errorMessage = error.localizedDescription
            let isRetryableError = errorMessage.contains("Failed to fetch") ||
                                   errorMessage.contains("Network") ||
                                   errorMessage.contains("timed out") ||
                                   errorMessage.contains("connection")
            
            if retriesLeft > 0 && isRetryableError {
                AppLogger.log("⚠️ Quote fetch failed, retrying... attempts left: \(retriesLeft)", category: "dex")
                try await Task.sleep(nanoseconds: retryDelayMs)
                return try await fetchQuoteWithRetry(params: params, retriesLeft: retriesLeft - 1)
            }
            
            throw SwapError.networkError(error.localizedDescription)
        }
    }
    
    /// Check if token approval is needed for swap
    func checkApproval(
        tokenAddress: String,
        ownerAddress: String,
        spenderAddress: String,
        amount: Decimal
    ) async throws -> ApprovalState {
        AppLogger.log("🔍 Checking approval for \(tokenAddress)", category: "dex")
        
        // Build eth_call for allowance check
        let ownerPadded = String(ownerAddress.dropFirst(2)).paddingToLeft(upTo: 64, using: "0")
        let spenderPadded = String(spenderAddress.dropFirst(2)).paddingToLeft(upTo: 64, using: "0")
        let data = "0xdd62ed3e" + ownerPadded + spenderPadded // allowance(address,address)
        
        let result = try await web3Client.ethCall(to: tokenAddress, data: data)
        
        guard let resultString = result as? String else {
            throw SwapError.networkError("Invalid allowance response")
        }
        
        // Parse hex allowance using safe parser for large numbers
        let allowanceValue: Decimal
        do {
            allowanceValue = try HexParser.parseToDecimal(resultString)
        } catch {
            throw SwapError.networkError("Failed to parse allowance: \(error.localizedDescription)")
        }
        
        let state: ApprovalState = allowanceValue >= amount ? .approved : .required
        AppLogger.log("   Allowance: \(allowanceValue), Required: \(amount), State: \(state)", category: "dex")
        
        approvalState = state
        return state
    }
    
    /// Approve token spending using Privy SDK with gas sponsorship
    /// Aligned with web: unlimited approval, proper confirmation polling, retry on allowance check
    func approveToken(
        tokenAddress: String,
        spenderAddress: String,
        amount: Decimal
    ) async throws {
        AppLogger.log("✍️ Approving \(tokenAddress) for spender \(spenderAddress)", category: "dex")
        
        approvalState = .pending
        transactionStatus = .approving
        
        // Build approval transaction data
        // approve(address spender, uint256 amount)
        // Function selector: 0x095ea7b3
        let spenderPadded = String(spenderAddress.dropFirst(2)).paddingToLeft(upTo: 64, using: "0")
        
        // Use max uint256 for unlimited approval (aligned with web UNLIMITED_ALLOWANCE)
        let maxAmount = String(repeating: "f", count: 64)
        let approvalData = "0x095ea7b3" + spenderPadded + maxAmount
        
        AppLogger.log("📝 Approval data: \(approvalData.prefix(20))...", category: "dex")
        
        // Get user's wallet address
        guard let userAddress = UserDefaults.standard.string(forKey: "userWalletAddress") else {
            transactionStatus = .failed
            throw SwapError.networkError("Wallet address not available")
        }
        
        do {
        // Send transaction via Privy
        let txHash = try await sendPrivyTransaction(
            to: tokenAddress,
            data: approvalData,
            value: "0x0",
            from: userAddress
        )
        
            lastTxHash = txHash
        AppLogger.log("✅ Token approval sent: \(txHash)", category: "dex")
        
            // Wait for confirmation with receipt polling (aligned with web)
            let result = try await waitForTransactionWithPolling(txHash)
            
            if result.success {
                AppLogger.log("✅ Token approval confirmed on-chain", category: "dex")
                
                // Re-check allowance with retry (aligned with web checkAllowanceWithRetry)
                await verifyAllowanceWithRetry(
                    tokenAddress: tokenAddress,
                    ownerAddress: userAddress,
                    spenderAddress: spenderAddress,
                    requiredAmount: amount
                )
        
        approvalState = .approved
                transactionStatus = .idle
            } else if result.possibleSuccess {
                AppLogger.log("⚠️ Approval may have succeeded, assuming approved", category: "dex")
                approvalState = .approved
                transactionStatus = .idle
            } else {
                throw result.error ?? SwapError.transactionFailed("Approval transaction failed")
            }
            
        } catch let error as SwapError {
            transactionStatus = .failed
            approvalState = .required
            throw error
        } catch {
            transactionStatus = .failed
            approvalState = .required
            throw mapTransactionError(error)
        }
    }
    
    /// Verify allowance with retry after approval (aligned with web checkAllowanceWithRetry)
    private func verifyAllowanceWithRetry(
        tokenAddress: String,
        ownerAddress: String,
        spenderAddress: String,
        requiredAmount: Decimal,
        retries: Int = 3,
        delaySeconds: UInt64 = 3
    ) async {
        for attempt in 1...retries {
            try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            
            do {
                let state = try await checkApproval(
                    tokenAddress: tokenAddress,
                    ownerAddress: ownerAddress,
                    spenderAddress: spenderAddress,
                    amount: requiredAmount
                )
                
                AppLogger.log("   Allowance re-check attempt \(attempt): \(state)", category: "dex")
                
                if state == .approved {
                    AppLogger.log("✅ Allowance confirmed sufficient!", category: "dex")
                    return
                }
            } catch {
                AppLogger.log("⚠️ Re-check allowance attempt \(attempt) failed: \(error.localizedDescription)", category: "dex")
            }
        }
        
        AppLogger.log("⚠️ Could not confirm allowance, assuming approval succeeded", category: "dex")
    }
    
    /// Execute swap transaction using Privy SDK with gas sponsorship
    /// Aligned with web: pre-swap allowance check, proper confirmation, detailed error handling
    func executeSwap(params: SwapParams) async throws -> String {
        AppLogger.log("🔄 Executing swap: \(params.amount) \(params.fromToken.symbol) → \(params.toToken.symbol)", category: "dex")
        
        // Verify we have a quote
        guard let quoteResponse = latestZeroExQuote else {
            throw SwapError.networkError("No quote available. Please get a quote first.")
        }
        
        // Pre-swap allowance check (aligned with web)
        AppLogger.log("🔍 Pre-swap allowance check...", category: "dex")
        let zeroExProxy = quoteResponse.allowanceTarget
        let currentApprovalState = try await checkApproval(
            tokenAddress: params.fromToken.address,
            ownerAddress: params.fromAddress,
            spenderAddress: zeroExProxy,
            amount: params.amount
        )
        
        if currentApprovalState == .required {
            AppLogger.log("⚠️ Pre-swap check: Insufficient allowance", category: "dex")
            throw SwapError.approvalRequired
        }
        
        AppLogger.log("✅ Pre-swap check passed", category: "dex")
        
        isLoading = true
        transactionStatus = .swapping
        defer { 
            isLoading = false
        }
        
        AppLogger.log("📊 Using 0x quote data:", category: "dex")
        AppLogger.log("   To: \(quoteResponse.to)", category: "dex")
        AppLogger.log("   Data: \(quoteResponse.data.prefix(66))...", category: "dex")
        AppLogger.log("   Value: \(quoteResponse.value)", category: "dex")
        
        do {
        // Send transaction via Privy using 0x quote data
        let txHash = try await sendPrivyTransaction(
            to: quoteResponse.to,
            data: quoteResponse.data,
            value: quoteResponse.value,
            from: params.fromAddress
        )
        
            lastTxHash = txHash
        AppLogger.log("✅ Swap transaction sent: \(txHash)", category: "dex")
        
            // Wait for confirmation with polling (aligned with web)
            let result = try await waitForTransactionWithPolling(txHash)
        
            if result.success {
                transactionStatus = .success
        AppLogger.log("✅ Swap confirmed: \(txHash)", category: "dex")
                return txHash
            } else if result.possibleSuccess {
                // Transaction may have succeeded - return hash anyway (aligned with web)
                transactionStatus = .success
                AppLogger.log("⚠️ Swap may have succeeded: \(txHash)", category: "dex")
                return txHash
            } else {
                transactionStatus = .failed
                throw result.error ?? SwapError.transactionFailed("Swap transaction failed")
            }
            
        } catch let error as SwapError {
            transactionStatus = .failed
            throw error
        } catch {
            transactionStatus = .failed
            throw mapTransactionError(error)
        }
    }
    
    /// Map generic errors to SwapError (aligned with web error handling)
    private func mapTransactionError(_ error: Error) -> SwapError {
        let message = error.localizedDescription.lowercased()
        
        if message.contains("rejected") || message.contains("denied") || message.contains("cancelled") {
            return .userRejected
        } else if message.contains("insufficient funds for transfer") || message.contains("exceeds the balance") {
            return .transactionFailed("Insufficient ETH for gas fees. Please add ETH to your wallet.")
        } else if message.contains("insufficient funds") {
            return .insufficientBalance(token: currentQuote?.fromToken.symbol ?? "token")
        } else if message.contains("slippage") {
            return .slippageTooHigh
        } else if message.contains("allowance") {
            return .approvalRequired
        } else if message.contains("aborted") || message.contains("abort") {
            return .transactionTimeout
        }
        
        return .networkError(error.localizedDescription)
    }
    
    /// Reset state (aligned with web resetSwap)
    func reset() {
        currentQuote = nil
        approvalState = .notRequired
        latestZeroExQuote = nil
        transactionStatus = .idle
        lastTxHash = nil
    }
    
    // MARK: - Privy Transaction Methods (REST API with sponsor: true)
    
    /// Environment configuration for Privy credentials
    private var environment: EnvironmentConfiguration { .current }
    
    /// Send transaction via Privy REST API with gas sponsorship (sponsor: true)
    /// This is the same approach as web's useSendTransaction with { sponsor: true }
    private func sendPrivyTransaction(
        to: String,
        data: String,
        value: String,
        from: String
    ) async throws -> String {
        AppLogger.log("🔐 Attempting to send transaction via Privy REST API with sponsor: true", category: "dex")
        
        // Get wallet ID from storage (required for REST API)
        guard let walletId = UserDefaults.standard.string(forKey: "userWalletId") else {
            AppLogger.log("❌ Missing Privy wallet ID", category: "dex")
            throw SwapError.networkError("Missing Privy wallet identifier. Please log out and log back in.")
        }
        
        AppLogger.log("📝 Preparing sponsored transaction:", category: "dex")
        AppLogger.log("   Wallet ID: \(walletId.prefix(20))...", category: "dex")
        AppLogger.log("   To: \(to)", category: "dex")
        AppLogger.log("   From: \(from)", category: "dex")
        AppLogger.log("   Data: \(data.prefix(66))...", category: "dex")
        AppLogger.log("   Value: \(value)", category: "dex")
        
        // Send via REST API with sponsor: true
        do {
            let txHash = try await sendSponsoredTransaction(
                to: to,
                from: from,
                data: data,
                value: value,
                walletId: walletId
            )
            AppLogger.log("✅ Sponsored transaction submitted: \(txHash)", category: "dex")
            AppLogger.log("💰 Gas sponsored via Privy REST API (sponsor: true)", category: "dex")
            return txHash
        } catch {
            AppLogger.log("❌ Sponsored transaction failed: \(error)", category: "dex")
            throw SwapError.networkError("Transaction failed: \(error.localizedDescription)")
        }
    }
    
    /// Send transaction via Privy REST API with sponsor: true
    /// Matches web implementation: POST /v1/wallets/{wallet_id}/rpc with sponsor: true
    private func sendSponsoredTransaction(
        to: String,
        from: String,
        data: String,
        value: String,
        walletId: String
    ) async throws -> String {
        // Validate Privy credentials
        guard !environment.privyAppID.isEmpty,
              !environment.privyAppSecret.isEmpty else {
            throw SwapError.networkError("Privy credentials missing. App ID or Secret not configured.")
        }
        
        // Request/Response types
        struct PrivyRPCRequest: Encodable {
            struct Params: Encodable {
                struct Transaction: Encodable {
                    let from: String
                    let to: String
                    let data: String
                    let value: String
                }
                let transaction: Transaction
            }
            let method: String
            let caip2: String
            let sponsor: Bool
            let params: Params
        }
        
        struct PrivyRPCResponse: Decodable {
            struct RPCError: Decodable {
                let code: Int?
                let message: String?
                let data: String?
            }
            let result: String?
            let error: RPCError?
        }
        
        // Build endpoint URL
        let endpointString = "https://api.privy.io/v1/wallets/\(walletId)/rpc"
        guard let endpoint = URL(string: endpointString) else {
            throw SwapError.networkError("Invalid Privy RPC URL")
        }
        
        // Ensure value has 0x prefix
        let formattedValue = value.lowercased().hasPrefix("0x") ? value : "0x\(value)"
        
        // Build request payload with sponsor: true (KEY DIFFERENCE from SDK)
        let payload = PrivyRPCRequest(
            method: "eth_sendTransaction",
            caip2: "eip155:1",  // Ethereum mainnet
            sponsor: true,      // 🎯 GAS SPONSORSHIP FLAG - Same as web!
            params: .init(
                transaction: .init(
                    from: from,
                    to: to,
                    data: data,
                    value: formattedValue
                )
            )
        )
        
        AppLogger.log("📤 Privy REST API Request:", category: "dex")
        AppLogger.log("   Endpoint: \(endpointString)", category: "dex")
        AppLogger.log("   Method: eth_sendTransaction", category: "dex")
        AppLogger.log("   Chain: eip155:1 (Ethereum mainnet)", category: "dex")
        AppLogger.log("   Sponsor: true ✅", category: "dex")
        
        // Encode payload
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let body = try encoder.encode(payload)
        
        // Build HTTP request
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(environment.privyAppID, forHTTPHeaderField: "privy-app-id")
        
        // Add authorization signature (HMAC-SHA256)
        if let signatureHeader = makePrivySignature(
            appSecret: environment.privyAppSecret,
            method: "POST",
            path: "/v1/wallets/\(walletId)/rpc",
            body: body
        ) {
            urlRequest.setValue(signatureHeader.signature, forHTTPHeaderField: "privy-authorization-signature")
            urlRequest.setValue(signatureHeader.timestamp, forHTTPHeaderField: "privy-request-timestamp")
        }
        
        // Add Basic Auth header
        let credentials = "\(environment.privyAppID):\(environment.privyAppSecret)"
        if let credentialData = credentials.data(using: .utf8) {
            let basicToken = credentialData.base64EncodedString()
            urlRequest.setValue("Basic \(basicToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Execute request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SwapError.networkError("Invalid response from Privy API")
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.log("📥 Privy API Response (\(httpResponse.statusCode)): \(responseString.prefix(500))", category: "dex")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            AppLogger.log("❌ Privy API error (\(httpResponse.statusCode)): \(message)", category: "dex")
            throw SwapError.networkError("Privy API failed (\(httpResponse.statusCode)): \(message)")
        }
        
        // Parse response
        let rpcResponse = try JSONDecoder().decode(PrivyRPCResponse.self, from: data)
        
        if let error = rpcResponse.error {
            let message = error.message ?? "Unknown RPC error"
            AppLogger.log("❌ Privy RPC error: \(message)", category: "dex")
            throw SwapError.networkError("Privy RPC error: \(message)")
        }
        
        guard let txHash = rpcResponse.result else {
            throw SwapError.networkError("No transaction hash returned from Privy API")
        }
        
        return txHash
    }
    
    /// Generate Privy authorization signature (HMAC-SHA256)
    /// Required for REST API authentication
    private func makePrivySignature(
        appSecret: String,
        method: String,
        path: String,
        body: Data
    ) -> (timestamp: String, signature: String)? {
        guard !appSecret.isEmpty else { return nil }
        
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        let message = "\(timestamp):\(method.uppercased()):\(path):\(bodyString)"
        
        let key = SymmetricKey(data: Data(appSecret.utf8))
        let signatureData = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        let encodedSignature = Data(signatureData).base64EncodedString()
        
        return (timestamp, encodedSignature)
    }
    
    /// Wait for transaction confirmation with receipt polling (aligned with web)
    /// Polls eth_getTransactionReceipt instead of fixed sleep
    private func waitForTransactionWithPolling(_ txHash: String) async throws -> TransactionResult {
        AppLogger.log("⏳ Waiting for transaction confirmation: \(txHash)", category: "dex")
        AppLogger.log("   Polling interval: \(confirmationPollIntervalMs / 1_000_000_000)s, max attempts: \(maxConfirmationAttempts)", category: "dex")
        
        for attempt in 1...maxConfirmationAttempts {
            // Wait before polling (except first attempt)
            if attempt > 1 {
                try await Task.sleep(nanoseconds: confirmationPollIntervalMs)
            }
            
            do {
                if let receipt = try await getTransactionReceipt(txHash) {
                    AppLogger.log("✅ Transaction receipt found at attempt \(attempt)", category: "dex")
                    AppLogger.log("   Block: \(receipt.blockNumber), Status: \(receipt.status ? "success" : "reverted")", category: "dex")
                    
                    if receipt.status {
                        return TransactionResult(
                            success: true,
                            possibleSuccess: true,
                            txHash: txHash,
                            error: nil,
                            receipt: receipt
                        )
                    } else {
                        return TransactionResult(
                            success: false,
                            possibleSuccess: false,
                            txHash: txHash,
                            error: .transactionFailed("Transaction reverted on-chain"),
                            receipt: receipt
                        )
                    }
                }
                
                AppLogger.log("   Attempt \(attempt)/\(maxConfirmationAttempts): Receipt not yet available", category: "dex")
                
            } catch {
                AppLogger.log("⚠️ Error polling receipt (attempt \(attempt)): \(error.localizedDescription)", category: "dex")
            }
        }
        
        // Timeout - transaction may have succeeded but we couldn't confirm
        // Aligned with web: return possibleSuccess = true
        AppLogger.log("⚠️ Transaction confirmation timeout. May have succeeded.", category: "dex")
        return TransactionResult(
            success: false,
            possibleSuccess: true,
            txHash: txHash,
            error: .transactionTimeout,
            receipt: nil
        )
    }
    
    /// Get transaction receipt via eth_getTransactionReceipt
    private func getTransactionReceipt(_ txHash: String) async throws -> TransactionReceipt? {
        let result = try await web3Client.getTransactionReceipt(txHash: txHash)
        
        // Check if result is null (transaction not yet mined)
        guard let resultDict = result as? [String: Any],
              let statusHex = resultDict["status"] as? String else {
            return nil
        }
        
        // Parse status (0x1 = success, 0x0 = reverted)
        let status = statusHex == "0x1"
        let blockNumber = resultDict["blockNumber"] as? String ?? "unknown"
        let gasUsed = resultDict["gasUsed"] as? String ?? "0"
        
        return TransactionReceipt(
            transactionHash: txHash,
            status: status,
            blockNumber: blockNumber,
            gasUsed: gasUsed
        )
    }
    
    /// Legacy method for backward compatibility
    @available(*, deprecated, message: "Use waitForTransactionWithPolling instead")
    private func waitForTransaction(_ txHash: String) async throws {
        let result = try await waitForTransactionWithPolling(txHash)
        if !result.success && !result.possibleSuccess {
            throw result.error ?? SwapError.transactionFailed("Transaction failed")
        }
    }
    
    /// Convert raw hex string to Privy Quantity type
    private func makeHexQuantity(_ rawValue: String) -> PrivySDK.EthereumRpcRequest.UnsignedEthTransaction.Quantity? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        
        let formatted: String
        if trimmed.lowercased().hasPrefix("0x") {
            formatted = trimmed
        } else {
            formatted = "0x\(trimmed)"
        }
        
        return .hexadecimalNumber(formatted)
    }
    
    // MARK: - Helpers
    
    private func toBaseUnits(_ amount: Decimal, decimals: Int) throws -> String {
        let nsDecimal = NSDecimalNumber(decimal: amount)
        let scaled = nsDecimal.multiplying(byPowerOf10: Int16(decimals))
        guard scaled != NSDecimalNumber.notANumber else {
            throw SwapError.invalidAmount
        }
        return scaled.stringValue
    }
    
    private func fromBaseUnits(_ value: String, decimals: Int) -> Decimal {
        let decimal = NSDecimalNumber(string: value)
        if decimal == NSDecimalNumber.notANumber {
            return 0
        }
        let divisor = NSDecimalNumber(decimal: pow10(decimals))
        return decimal.dividing(by: divisor).decimalValue
    }
    
    private func decimalFromString(_ value: String) -> Decimal? {
        guard let decimal = Decimal(string: value) else { return nil }
        return decimal
    }
    
    private func pow10(_ exponent: Int) -> Decimal {
        var result = Decimal(1)
        for _ in 0..<max(0, exponent) {
            result *= 10
        }
        return result
    }
}

// MARK: - String Extension

private extension String {
    func paddingToLeft(upTo length: Int, using element: String) -> String {
        let padCount = length - self.count
        guard padCount > 0 else { return self }
        return String(repeating: element, count: padCount) + self
    }
}
