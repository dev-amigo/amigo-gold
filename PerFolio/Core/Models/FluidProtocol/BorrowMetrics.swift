import Foundation

/// Real-time calculated metrics for the borrow UI
/// Updates as user types in collateral/borrow amounts
struct BorrowMetrics {
    
    // MARK: - Input Values
    
    /// User-entered collateral amount (PAXG)
    let collateralAmount: Decimal
    
    /// User-entered borrow amount (USDC)
    let borrowAmount: Decimal
    
    /// Current PAXG price in USD
    let paxgPrice: Decimal
    
    /// Vault configuration (LTV limits, liquidation threshold)
    let vaultConfig: VaultConfig
    
    // MARK: - Computed Properties
    
    /// Collateral value in USD (collateral × PAXG price)
    var collateralValueUSD: Decimal {
        return collateralAmount * paxgPrice
    }
    
    /// Maximum borrowable amount at max LTV (collateral value × max LTV)
    var maxBorrowableUSD: Decimal {
        return collateralValueUSD * (vaultConfig.maxLTV / 100)
    }
    
    /// Current Loan-to-Value ratio (borrow / collateral × 100)
    var currentLTV: Decimal {
        guard collateralValueUSD > 0 else { return 0 }
        return (borrowAmount / collateralValueUSD) * 100
    }
    
    /// Health Factor (collateral × liq threshold / debt)
    /// HF > 1.0: Position is safe
    /// HF ≤ 1.0: Position can be liquidated
    var healthFactor: Decimal {
        guard borrowAmount > 0 else { return Decimal(Double.infinity) }
        guard collateralValueUSD > 0 else { return 0 }
        
        let numerator = collateralValueUSD * (vaultConfig.liquidationThreshold / 100)
        return numerator / borrowAmount
    }
    
    /// PAXG price at which position will be liquidated (HF = 1.0)
    var liquidationPrice: Decimal {
        guard collateralAmount > 0 else { return 0 }
        guard vaultConfig.liquidationThreshold > 0 else { return 0 }
        
        let denominator = collateralAmount * (vaultConfig.liquidationThreshold / 100)
        return borrowAmount / denominator
    }
    
    // MARK: - Validation Flags
    
    /// Is LTV dangerously high (> 75%)?
    var isHighLTV: Bool {
        return currentLTV > vaultConfig.maxLTV
    }
    
    /// Is health factor unsafe (< 1.5)?
    var isUnsafeHealth: Bool {
        return healthFactor < 1.5 && !healthFactor.isInfinite
    }
    
    /// Can user proceed with this borrow?
    var canBorrow: Bool {
        return !isUnsafeHealth && 
               !isHighLTV && 
               collateralAmount > 0 && 
               borrowAmount > 0 &&
               borrowAmount <= maxBorrowableUSD
    }
    
    // MARK: - Display Helpers
    
    /// Format health factor for UI (handle infinity)
    var formattedHealthFactor: String {
        if healthFactor.isInfinite {
            return "∞"
        }
        if healthFactor > 100 {
            return ">100"
        }
        return String(format: "%.2f", NSDecimalNumber(decimal: healthFactor).doubleValue)
    }
    
    /// Status text based on health factor
    var healthStatus: String {
        if healthFactor.isInfinite {
            return "✅ Excellent"
        } else if healthFactor > 2.0 {
            return "✅ Healthy"
        } else if healthFactor > 1.5 {
            return "⚠️ Moderate"
        } else if healthFactor > 1.0 {
            return "🚫 Low"
        } else {
            return "💀 Liquidation"
        }
    }
    
    /// Status text based on LTV
    var ltvStatus: String {
        if currentLTV < 50 {
            return "✅ Safe"
        } else if currentLTV < 70 {
            return "⚠️ Moderate"
        } else if currentLTV <= vaultConfig.maxLTV {
            return "⚠️ High"
        } else {
            return "🚫 Too High"
        }
    }
    
    /// Format currency with 2 decimals
    func formatUSD(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
    
    /// Format percentage with 1 decimal
    func formatPercentage(_ value: Decimal) -> String {
        return String(format: "%.1f%%", NSDecimalNumber(decimal: value).doubleValue)
    }
}

// MARK: - Mock Data

extension BorrowMetrics {
    static var mock: BorrowMetrics {
        return BorrowMetrics(
            collateralAmount: 0.1,  // 0.1 PAXG
            borrowAmount: 100.0,    // $100 USDC
            paxgPrice: 4183.0,      // $4,183/oz
            vaultConfig: .mock
        )
    }
    
    static var mockHighLTV: BorrowMetrics {
        return BorrowMetrics(
            collateralAmount: 0.1,  // 0.1 PAXG
            borrowAmount: 320.0,    // $320 USDC (> 75% LTV)
            paxgPrice: 4183.0,
            vaultConfig: .mock
        )
    }
    
    static var mockUnsafeHealth: BorrowMetrics {
        return BorrowMetrics(
            collateralAmount: 0.1,  // 0.1 PAXG
            borrowAmount: 300.0,    // $300 USDC (HF = 1.19)
            paxgPrice: 4183.0,
            vaultConfig: .mock
        )
    }
}

