import SwiftUI
import Combine

@MainActor
final class WithdrawViewModel: ObservableObject {
    
    // MARK: - Types
    
    enum ViewState: Equatable {
        case loading
        case ready
        case error(String)
        
        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading),
                 (.ready, .ready):
                return true
            case (.error(let lhsMsg), .error(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published var usdcAmount: String = ""
    @Published var usdcBalance: Decimal = 0
    @Published var viewState: ViewState = .loading
    
    // Exchange rate (1 USDC = ₹83.00 for withdrawal)
    private let usdcToInrRate: Decimal = 83.00
    private let providerFeePercentage: Decimal = 0.025  // 2.5%
    
    // MARK: - Private Properties
    
    private let erc20Contract: ERC20Contract
    private let transakService: TransakService
    private var walletAddress: String? {
        UserDefaults.standard.string(forKey: "userWalletAddress")
    }
    
    // MARK: - Computed Properties
    
    var formattedUSDCBalance: String {
        CurrencyFormatter.formatToken(usdcBalance, symbol: "USDC")
    }
    
    var usdcBalanceINR: String {
        let inrValue = usdcBalance * usdcToInrRate
        return CurrencyFormatter.formatINR(inrValue)
    }
    
    var estimatedINRAmount: String {
        guard let amount = Decimal(string: usdcAmount), amount > 0 else {
            return "≈ ₹0.00"
        }
        
        let grossINR = amount * usdcToInrRate
        let fee = grossINR * providerFeePercentage
        let netINR = grossINR - fee
        
        return CurrencyFormatter.formatINR(netINR)
    }
    
    var providerFeeAmount: String {
        guard let amount = Decimal(string: usdcAmount), amount > 0 else {
            return "₹0.00"
        }
        
        let grossINR = amount * usdcToInrRate
        let fee = grossINR * providerFeePercentage
        
        return CurrencyFormatter.formatINR(fee)
    }
    
    var isValidAmount: Bool {
        guard let amount = Decimal(string: usdcAmount) else {
            return false
        }
        return amount > 0 && amount <= usdcBalance
    }
    
    // MARK: - Initialization
    
    nonisolated init(
        erc20Contract: ERC20Contract = ERC20Contract(),
        transakService: TransakService = TransakService()
    ) {
        self.erc20Contract = erc20Contract
        self.transakService = transakService
        
        Task { @MainActor in
            AppLogger.log("💸 WithdrawViewModel initialized", category: "withdraw")
            await loadBalance()
        }
    }
    
    // MARK: - Public Methods
    
    func loadBalance() async {
        guard let walletAddress = walletAddress else {
            AppLogger.log("⚠️ No wallet address available", category: "withdraw")
            viewState = .error("Wallet address not available")
            return
        }
        
        viewState = .loading
        
        do {
            let balances = try await erc20Contract.balancesOf(
                tokens: [.usdc],
                address: walletAddress
            )
            
            if let usdcBalance = balances.first(where: { $0.symbol == "USDC" }) {
                self.usdcBalance = usdcBalance.decimalBalance
                viewState = .ready
                AppLogger.log("✅ USDC balance loaded: \(usdcBalance.decimalBalance)", category: "withdraw")
            } else {
                viewState = .error("Failed to fetch USDC balance")
            }
        } catch {
            viewState = .error("Failed to load balance: \(error.localizedDescription)")
            AppLogger.log("❌ Failed to load USDC balance: \(error.localizedDescription)", category: "withdraw")
        }
    }
    
    func setPresetAmount(_ preset: String) {
        guard usdcBalance > 0 else {
            usdcAmount = ""
            return
        }
        
        let amount: Decimal
        switch preset {
        case "50%":
            amount = usdcBalance * 0.5
        case "Max":
            amount = usdcBalance
        default:
            return
        }
        
        usdcAmount = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
        AppLogger.log("📝 Set withdraw amount to \(preset): \(usdcAmount) USDC", category: "withdraw")
    }
    
    func validateAndProceed() -> (isValid: Bool, errorMessage: String?) {
        guard let amount = Decimal(string: usdcAmount) else {
            return (false, "Please enter a valid amount")
        }
        
        if amount <= 0 {
            return (false, "Amount must be greater than 0")
        }
        
        if amount > usdcBalance {
            return (false, "Insufficient USDC balance")
        }
        
        // Transak minimum is ~$10
        if amount < 10 {
            return (false, "Minimum withdrawal is 10 USDC")
        }
        
        return (true, nil)
    }
    
    /// Build Transak widget URL for withdrawal
    func buildTransakURL() throws -> URL {
        AppLogger.log("🌐 Building Transak URL for withdrawal", category: "withdraw")
        AppLogger.log("   Amount: \(usdcAmount) USDC", category: "withdraw")
        
        return try transakService.buildWithdrawURL(
            cryptoAmount: usdcAmount,
            cryptoCurrency: "USDC",
            fiatCurrency: "INR"
        )
    }
}

