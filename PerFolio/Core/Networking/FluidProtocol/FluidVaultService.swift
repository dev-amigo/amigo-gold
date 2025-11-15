import Foundation
import Combine
import PrivySDK

/// Core service for interacting with Fluid Protocol vaults
/// Handles borrow execution, position management, and state tracking
@MainActor
final class FluidVaultService: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isLoading = false
    @Published var vaultConfig: VaultConfig?
    @Published var paxgPrice: Decimal = 0
    @Published var currentAPY: Decimal = 0
    
    // MARK: - Dependencies
    
    private let web3Client: Web3Client
    private let erc20Contract: ERC20Contract
    private let vaultConfigService: VaultConfigService
    private let priceOracleService: PriceOracleService
    private let apyService: BorrowAPYService
    
    // MARK: - Initialization
    
    init(
        web3Client: Web3Client = Web3Client(),
        erc20Contract: ERC20Contract = ERC20Contract(),
        vaultConfigService: VaultConfigService? = nil,
        priceOracleService: PriceOracleService? = nil,
        apyService: BorrowAPYService? = nil
    ) {
        self.web3Client = web3Client
        self.erc20Contract = erc20Contract
        self.vaultConfigService = vaultConfigService ?? VaultConfigService(web3Client: web3Client)
        self.priceOracleService = priceOracleService ?? PriceOracleService()
        self.apyService = apyService ?? BorrowAPYService(web3Client: web3Client)
        
        AppLogger.log("🏦 FluidVaultService initialized", category: "fluid")
    }
    
    // MARK: - Initialize (Load All Data)
    
    /// Load all required data for borrow screen
    /// Fetches vault config, PAXG price, and current APY in parallel
    func initialize() async throws {
        isLoading = true
        defer { isLoading = false }
        
        AppLogger.log("🔄 Initializing Fluid vault data...", category: "fluid")
        
        do {
            // Fetch all data in parallel for speed
            async let config = vaultConfigService.fetchVaultConfig()
            async let price = priceOracleService.fetchPAXGPrice()
            async let apy = apyService.fetchBorrowAPY()
            
            (vaultConfig, paxgPrice, currentAPY) = try await (config, price, apy)
            
            AppLogger.log("✅ Fluid vault initialized:", category: "fluid")
            AppLogger.log("   PAXG Price: $\(paxgPrice)", category: "fluid")
            AppLogger.log("   Max LTV: \(vaultConfig?.maxLTV ?? 0)%", category: "fluid")
            AppLogger.log("   Borrow APY: \(currentAPY)%", category: "fluid")
            
        } catch {
            AppLogger.log("❌ Fluid initialization failed: \(error.localizedDescription)", category: "fluid")
            throw error
        }
    }
    
    // MARK: - Execute Borrow (Phase 5 - Privy Integration)
    
    /// Execute the full borrow transaction flow
    /// Steps: 1) Approve PAXG, 2) Deposit + Borrow (atomic operation)
    /// - Parameter request: Borrow request with collateral and borrow amounts
    /// - Returns: Position NFT ID
    ///
    /// Note: This will be implemented in Phase 5 with Privy signing
    func executeBorrow(request: BorrowRequest) async throws -> String {
        AppLogger.log("🏦 Starting borrow execution...", category: "fluid")
        AppLogger.log("   Collateral: \(request.collateralAmount) PAXG", category: "fluid")
        AppLogger.log("   Borrow: \(request.borrowAmount) USDC", category: "fluid")
        
        // Validate request
        guard request.isValid else {
            throw FluidVaultError.invalidRequest
        }
        
        // Step 1: Check PAXG allowance
        let allowanceNeeded = try await checkPAXGAllowance(
            owner: request.userAddress,
            spender: request.vaultAddress,
            amount: request.collateralAmount
        )
        
        if allowanceNeeded {
            // Step 2: Approve PAXG spending
            AppLogger.log("📝 Approving PAXG spending...", category: "fluid")
            let approveTxHash = try await approvePAXG(
                spender: request.vaultAddress,
                amount: request.collateralAmount,
                from: request.userAddress
            )
            AppLogger.log("✅ PAXG approved: \(approveTxHash)", category: "fluid")
            
            // Wait for confirmation
            try await waitForTransaction(approveTxHash)
        } else {
            AppLogger.log("✅ PAXG already approved", category: "fluid")
        }
        
        // Step 3: Execute operate (deposit + borrow)
        AppLogger.log("💰 Executing deposit + borrow...", category: "fluid")
        let operateTxHash = try await executeOperate(
            request: request
        )
        AppLogger.log("✅ Operate transaction: \(operateTxHash)", category: "fluid")
        
        // Wait for confirmation
        try await waitForTransaction(operateTxHash)
        
        // Step 4: Extract NFT ID from transaction receipt
        let nftId = try await extractNFTId(from: operateTxHash)
        
        AppLogger.log("🎉 Borrow complete! Position NFT: #\(nftId)", category: "fluid")
        
        return nftId
    }
    
    // MARK: - Private Helpers
    
    /// Check if PAXG approval is needed
    private func checkPAXGAllowance(owner: String, spender: String, amount: Decimal) async throws -> Bool {
        // Encode allowance(address owner, address spender) call
        let functionSelector = "0xdd62ed3e"
        
        let cleanOwner = owner.replacingOccurrences(of: "0x", with: "").paddingLeft(to: 64, with: "0")
        let cleanSpender = spender.replacingOccurrences(of: "0x", with: "").paddingLeft(to: 64, with: "0")
        
        let callData = functionSelector + cleanOwner + cleanSpender
        
        let result = try await web3Client.ethCall(
            to: ContractAddresses.paxg,
            data: callData
        )
        
        // Parse allowance (hex to Decimal)
        let allowance = parseUint256(result)
        let amountInWei = amount * pow(Decimal(10), 18)
        
        return allowance < amountInWei
    }
    
    /// Approve PAXG spending (Privy integration in Phase 5)
    private func approvePAXG(spender: String, amount: Decimal, from: String) async throws -> String {
        // Build approve transaction
        // approve(address spender, uint256 amount)
        let functionSelector = "0x095ea7b3"
        
        let cleanSpender = spender.replacingOccurrences(of: "0x", with: "").paddingLeft(to: 64, with: "0")
        
        // Amount in Wei (18 decimals)
        let amountInWei = amount * pow(Decimal(10), 18)
        let amountHex = decimalToHex(amountInWei).paddingLeft(to: 64, with: "0")
        
        let txData = functionSelector + cleanSpender + amountHex
        
        // TODO: Phase 5 - Sign with Privy
        // For now, throw not implemented
        throw FluidVaultError.notImplemented("Privy signing integration pending (Phase 5)")
    }
    
    /// Execute operate call (deposit + borrow)
    private func executeOperate(request: BorrowRequest) async throws -> String {
        // Build operate transaction
        // operate(uint256 nftId, int256 newCol, int256 newDebt, address to)
        let functionSelector = "0x..." // TODO: Get correct selector
        
        // nftId = 0 (create new position)
        let nftId = "0".paddingLeft(to: 64, with: "0")
        
        // newCol = positive collateral amount in Wei
        let collateralWei = request.collateralAmount * pow(Decimal(10), 18)
        let collateralHex = decimalToHex(collateralWei).paddingLeft(to: 64, with: "0")
        
        // newDebt = positive borrow amount in smallest units
        let borrowSmallest = request.borrowAmount * pow(Decimal(10), 6)
        let borrowHex = decimalToHex(borrowSmallest).paddingLeft(to: 64, with: "0")
        
        // to = user address
        let cleanAddress = request.userAddress.replacingOccurrences(of: "0x", with: "").paddingLeft(to: 64, with: "0")
        
        let txData = functionSelector + nftId + collateralHex + borrowHex + cleanAddress
        
        // TODO: Phase 5 - Sign with Privy
        throw FluidVaultError.notImplemented("Privy signing integration pending (Phase 5)")
    }
    
    /// Wait for transaction confirmation
    private func waitForTransaction(_ txHash: String) async throws {
        AppLogger.log("⏳ Waiting for transaction confirmation: \(txHash)", category: "fluid")
        // TODO: Implement polling logic
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds placeholder
    }
    
    /// Extract position NFT ID from transaction receipt
    private func extractNFTId(from txHash: String) async throws -> String {
        // Look for ERC721 Transfer event in transaction logs
        // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
        
        // TODO: Implement log parsing
        // For now, return mock ID
        return "1"
    }
    
    // MARK: - Utility Functions
    
    private func parseUint256(_ hexString: String) -> Decimal {
        let cleanHex = hexString.replacingOccurrences(of: "0x", with: "")
        var result: Decimal = 0
        for char in cleanHex {
            if let digit = char.hexDigitValue {
                result = result * 16 + Decimal(digit)
            }
        }
        return result
    }
    
    private func decimalToHex(_ value: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: value).intValue
        return String(intValue, radix: 16)
    }
}

// MARK: - Errors

enum FluidVaultError: LocalizedError {
    case invalidRequest
    case insufficientBalance
    case exceedsMaxLTV
    case unsafeHealthFactor
    case approvalFailed
    case operateFailed
    case nftIdNotFound
    case transactionFailed(String)
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Invalid borrow request"
        case .insufficientBalance:
            return "Insufficient PAXG balance"
        case .exceedsMaxLTV:
            return "Borrow amount exceeds maximum LTV"
        case .unsafeHealthFactor:
            return "Health factor too low - reduce borrow or add collateral"
        case .approvalFailed:
            return "Failed to approve PAXG spending"
        case .operateFailed:
            return "Failed to execute borrow operation"
        case .nftIdNotFound:
            return "Could not extract position NFT ID"
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        case .notImplemented(let feature):
            return "Not yet implemented: \(feature)"
        }
    }
}

