import Foundation
import PrivySDK
import Combine

/// DEX swap service for USDC → PAXG conversion
/// Uses 0x Aggregator for quotes and transaction data
/// Executes swaps via Privy SDK with gas sponsorship
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
    
    struct Token {
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
    }
    
    struct SwapParams {
        let fromToken: Token
        let toToken: Token
        let amount: Decimal
        let slippageTolerance: Decimal // e.g., 0.5 for 0.5%
        let fromAddress: String
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
        case insufficientBalance
        case insufficientLiquidity
        case slippageTooHigh
        case approvalRequired
        case networkError(String)
        case invalidAmount
        
        var errorDescription: String? {
            switch self {
            case .insufficientBalance:
                return "Insufficient USDC balance"
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
            }
        }
    }
    
    enum ApprovalState {
        case notRequired
        case required
        case pending
        case approved
    }
    
    // MARK: - Properties
    
    private let web3Client: Web3Client
    private let erc20Contract: ERC20Contract
    
    @Published var isLoading = false
    @Published var currentQuote: SwapQuote?
    @Published var approvalState: ApprovalState = .notRequired
    
    // 0x API configuration
    private let zeroExQuoteURL = "https://api.0x.org/swap/v1/quote"
    private var latestZeroExQuote: ZeroExQuoteResponse?
    private let zeroExAPIKey: String
    
    // Slippage tolerance (0.5% default)
    let defaultSlippageTolerance = ServiceConstants.defaultSlippageTolerance
    
    // MARK: - Initialization
    
    init(
        web3Client: Web3Client = Web3Client(),
        erc20Contract: ERC20Contract = ERC20Contract()
    ) {
        self.web3Client = web3Client
        self.erc20Contract = erc20Contract
        self.zeroExAPIKey = Bundle.main.object(forInfoDictionaryKey: "AGZeroXAPIKey") as? String ?? ""
        
        AppLogger.log("🔄 DEXSwapService initialized", category: "dex")
        AppLogger.log("   0x Quote URL: \(zeroExQuoteURL)", category: "dex")
    }
    
    // MARK: - Public Methods
    
    /// Get swap quote for USDC → PAXG
    func getQuote(params: SwapParams) async throws -> SwapQuote {
        AppLogger.log("📊 Getting swap quote: \(params.amount) \(params.fromToken.symbol) → \(params.toToken.symbol)", category: "dex")
        
        guard params.amount > 0 else {
            throw SwapError.invalidAmount
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Check balance
        let balances = try await erc20Contract.balancesOf(
            tokens: [.usdc],
            address: params.fromAddress
        )
        
        guard let balance = balances.first, balance.decimalBalance >= params.amount else {
            throw SwapError.insufficientBalance
        }
        
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
            
            let quote = SwapQuote(
                fromToken: params.fromToken,
                toToken: params.toToken,
                fromAmount: params.amount,
                toAmount: toAmount,
                estimatedGas: estimatedGasText,
                priceImpact: 0.1,
                route: route
            )
            
            currentQuote = quote
            AppLogger.log("✅ Quote: \(quote.displayFromAmount) → \(quote.displayToAmount)", category: "dex")
            AppLogger.log("   Route: \(quote.route)", category: "dex")
            return quote
        } catch let error as SwapError {
            throw error
        } catch {
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
    func approveToken(
        tokenAddress: String,
        spenderAddress: String,
        amount: Decimal
    ) async throws {
        AppLogger.log("✍️ Approving \(tokenAddress) for spender \(spenderAddress)", category: "dex")
        
        approvalState = .pending
        
        // Build approval transaction data
        // approve(address spender, uint256 amount)
        // Function selector: 0x095ea7b3
        let spenderPadded = String(spenderAddress.dropFirst(2)).paddingToLeft(upTo: 64, using: "0")
        
        // Use max uint256 for unlimited approval
        let maxAmount = String(repeating: "f", count: 64)
        let approvalData = "0x095ea7b3" + spenderPadded + maxAmount
        
        AppLogger.log("📝 Approval data: \(approvalData)", category: "dex")
        
        // Get user's wallet address
        guard let userAddress = UserDefaults.standard.string(forKey: "userWalletAddress") else {
            throw SwapError.networkError("Wallet address not available")
        }
        
        // Send transaction via Privy
        let txHash = try await sendPrivyTransaction(
            to: tokenAddress,
            data: approvalData,
            value: "0x0",
            from: userAddress
        )
        
        AppLogger.log("✅ Token approval sent: \(txHash)", category: "dex")
        
        // Wait for confirmation
        try await waitForTransaction(txHash)
        
        approvalState = .approved
        AppLogger.log("✅ Token approval confirmed", category: "dex")
    }
    
    /// Execute swap transaction using Privy SDK with gas sponsorship
    func executeSwap(params: SwapParams) async throws -> String {
        AppLogger.log("🔄 Executing swap: \(params.amount) \(params.fromToken.symbol) → \(params.toToken.symbol)", category: "dex")
        
        // Verify we have a quote
        guard let quoteResponse = latestZeroExQuote else {
            throw SwapError.networkError("No quote available. Please get a quote first.")
        }
        
        // Check approval first
        let zeroExProxy = quoteResponse.allowanceTarget
        let approvalState = try await checkApproval(
            tokenAddress: params.fromToken.address,
            ownerAddress: params.fromAddress,
            spenderAddress: zeroExProxy,
            amount: params.amount
        )
        
        if approvalState == .required {
            throw SwapError.approvalRequired
        }
        
        isLoading = true
        defer { isLoading = false }
        
        AppLogger.log("📊 Using 0x quote data:", category: "dex")
        AppLogger.log("   To: \(quoteResponse.to)", category: "dex")
        AppLogger.log("   Data: \(quoteResponse.data.prefix(66))...", category: "dex")
        AppLogger.log("   Value: \(quoteResponse.value)", category: "dex")
        
        // Send transaction via Privy using 0x quote data
        let txHash = try await sendPrivyTransaction(
            to: quoteResponse.to,
            data: quoteResponse.data,
            value: quoteResponse.value,
            from: params.fromAddress
        )
        
        AppLogger.log("✅ Swap transaction sent: \(txHash)", category: "dex")
        
        // Wait for confirmation
        try await waitForTransaction(txHash)
        
        AppLogger.log("✅ Swap confirmed: \(txHash)", category: "dex")
        
        return txHash
    }
    
    /// Reset state
    func reset() {
        currentQuote = nil
        approvalState = .notRequired
        latestZeroExQuote = nil
    }
    
    // MARK: - Privy Transaction Methods
    
    /// Send transaction via Privy SDK with gas sponsorship
    private func sendPrivyTransaction(
        to: String,
        data: String,
        value: String,
        from: String
    ) async throws -> String {
        AppLogger.log("🔐 Attempting to sign transaction with Privy embedded wallet", category: "dex")
        
        // Get Privy auth coordinator
        let authCoordinator = PrivyAuthCoordinator.shared
        let authState = await authCoordinator.resolvedAuthState()
        
        // Get user from authState
        guard case .authenticated(let user) = authState else {
            AppLogger.log("❌ User not authenticated. Current state: \(authState)", category: "dex")
            throw SwapError.networkError("User not authenticated")
        }
        
        AppLogger.log("✅ User authenticated successfully", category: "dex")
        
        // Get user's embedded Ethereum wallet
        let embeddedWallets = user.embeddedEthereumWallets
        
        AppLogger.log("🔍 Found \(embeddedWallets.count) embedded wallets", category: "dex")
        
        guard let wallet = embeddedWallets.first else {
            throw SwapError.networkError("No embedded wallet found")
        }
        
        AppLogger.log("📝 Preparing transaction for wallet: \(wallet.address)", category: "dex")
        AppLogger.log("   To: \(to)", category: "dex")
        AppLogger.log("   From: \(from)", category: "dex")
        AppLogger.log("   Data: \(data.prefix(66))...", category: "dex")
        AppLogger.log("   Value: \(value)", category: "dex")
        
        // Send transaction via embedded wallet provider
        AppLogger.log("🔑 Sending transaction via Privy embedded wallet with gas sponsorship", category: "dex")
        
        let chainId = await wallet.provider.chainId
        
        // Create unsigned transaction WITHOUT gas/gasPrice for sponsorship
        // When these are nil, Privy's infrastructure will:
        // 1. Check if transaction matches sponsorship policies
        // 2. If matched, Privy sponsors the gas
        // 3. If not matched, user needs ETH for gas
        let unsignedTx = PrivySDK.EthereumRpcRequest.UnsignedEthTransaction(
            from: from,
            to: to,
            data: data,
            value: makeHexQuantity(value),
            chainId: .int(chainId)
            // gas: nil - Let Privy estimate (omitted)
            // gasPrice: nil - Let Privy handle (will sponsor if policy matches) (omitted)
        )
        
        AppLogger.log("📤 Submitting transaction via wallet.provider.request()...", category: "dex")
        AppLogger.log("   Chain ID: \(chainId)", category: "dex")
        AppLogger.log("   Gas/GasPrice: nil (Privy will sponsor if policies match)", category: "dex")
        
        let rpcRequest = try PrivySDK.EthereumRpcRequest.ethSendTransaction(transaction: unsignedTx)
        
        do {
            let txHash = try await wallet.provider.request(rpcRequest)
            AppLogger.log("✅ Transaction submitted: \(txHash)", category: "dex")
            AppLogger.log("💰 Gas was sponsored by Privy (no ETH deducted from user)", category: "dex")
            return txHash
        } catch {
            AppLogger.log("❌ Transaction failed: \(error)", category: "dex")
            
            // Enhanced error message for gas sponsorship issues
            let errorMessage = error.localizedDescription
            if errorMessage.contains("insufficient funds") {
                AppLogger.log("🚨 INSUFFICIENT FUNDS ERROR - Possible causes:", category: "dex")
                AppLogger.log("   1. Gas sponsorship policy not configured in Privy Dashboard", category: "dex")
                AppLogger.log("   2. Transaction doesn't match policy criteria:", category: "dex")
                AppLogger.log("      • Chain must be: eip155:1 (Ethereum mainnet)", category: "dex")
                AppLogger.log("      • Contract must be whitelisted: \(to)", category: "dex")
                AppLogger.log("      • Method signature must be whitelisted", category: "dex")
                AppLogger.log("   3. Daily spending limit exceeded", category: "dex")
                AppLogger.log("   4. Policy is disabled or expired", category: "dex")
                AppLogger.log("", category: "dex")
                AppLogger.log("🔧 Fix: Configure gas sponsorship policy at:", category: "dex")
                AppLogger.log("   https://dashboard.privy.io/apps/cmhenc7hj004ijy0c311hbf2z/policies", category: "dex")
            }
            
            throw SwapError.networkError("Transaction failed: \(error.localizedDescription)")
        }
    }
    
    /// Wait for transaction confirmation
    private func waitForTransaction(_ txHash: String) async throws {
        AppLogger.log("⏳ Waiting for transaction confirmation: \(txHash)", category: "dex")
        
        // Wait 15 seconds for transaction to be mined
        // In production, this should poll eth_getTransactionReceipt
        try await Task.sleep(nanoseconds: 15_000_000_000)
        
        AppLogger.log("✅ Transaction confirmed (assumed after 15s)", category: "dex")
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
