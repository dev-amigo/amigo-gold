import Foundation

/// Core calculation engine for borrow feature
/// Contains all formulas for LTV, health factor, liquidation price, etc.
/// All calculations match the web app's implementation
class BorrowCalculationEngine {
    
    // MARK: - Maximum Borrowable Amount
    
    /// Calculate the maximum amount user can borrow at max LTV
    /// - Parameters:
    ///   - collateralAmount: Amount of PAXG deposited
    ///   - paxgPrice: Current PAXG price in USD
    ///   - maxLTV: Maximum loan-to-value ratio (e.g., 75.0 = 75%)
    /// - Returns: Maximum borrowable USD amount
    ///
    /// Formula: Max Borrow = Collateral Value × (Max LTV / 100)
    /// Example: 0.1 PAXG × $4,183 × 0.75 = $313.73
    static func calculateMaxBorrow(
        collateralAmount: Decimal,
        paxgPrice: Decimal,
        maxLTV: Decimal
    ) -> Decimal {
        let collateralValueUSD = collateralAmount * paxgPrice
        return collateralValueUSD * (maxLTV / 100)
    }
    
    // MARK: - Health Factor (HF)
    
    /// Calculate position health factor
    /// - Parameters:
    ///   - collateralValueUSD: Total collateral value in USD
    ///   - debtValueUSD: Total debt value in USD
    ///   - liquidationThreshold: Threshold percentage (e.g., 85.0 = 85%)
    /// - Returns: Health factor (HF > 1.0 = safe, HF ≤ 1.0 = liquidation)
    ///
    /// Formula: HF = (Collateral Value × Liquidation Threshold %) / Debt Value
    /// Example: ($418.30 × 0.85) / $100 = 3.56
    ///
    /// Interpretation:
    /// - HF > 1.0: Position is safe
    /// - HF ≤ 1.0: Position can be liquidated
    /// - HF = ∞: No debt (no risk)
    static func calculateHealthFactor(
        collateralValueUSD: Decimal,
        debtValueUSD: Decimal,
        liquidationThreshold: Decimal
    ) -> Decimal {
        // No debt = infinite health factor
        guard debtValueUSD > 0 else { return Decimal(Double.infinity) }
        
        // No collateral = zero health factor (immediate liquidation)
        guard collateralValueUSD > 0 else { return 0 }
        
        let numerator = collateralValueUSD * (liquidationThreshold / 100)
        let healthFactor = numerator / debtValueUSD
        
        return healthFactor
    }
    
    // MARK: - Loan-to-Value Ratio (LTV)
    
    /// Calculate current loan-to-value ratio
    /// - Parameters:
    ///   - collateralValueUSD: Total collateral value in USD
    ///   - debtValueUSD: Total debt value in USD
    /// - Returns: LTV percentage (e.g., 52.5 = 52.5%)
    ///
    /// Formula: LTV = (Debt / Collateral Value) × 100
    /// Example: ($100 / $418.30) × 100 = 23.9%
    static func calculateCurrentLTV(
        collateralValueUSD: Decimal,
        debtValueUSD: Decimal
    ) -> Decimal {
        guard collateralValueUSD > 0 else { return 0 }
        return (debtValueUSD / collateralValueUSD) * 100
    }
    
    // MARK: - Liquidation Price
    
    /// Calculate PAXG price at which position will be liquidated (HF = 1.0)
    /// - Parameters:
    ///   - collateralAmount: Amount of PAXG deposited
    ///   - debtValueUSD: Total debt value in USD
    ///   - liquidationThreshold: Threshold percentage (e.g., 85.0 = 85%)
    /// - Returns: PAXG price in USD at liquidation
    ///
    /// Formula: Liquidation Price = Debt / (Collateral Amount × Liquidation Threshold %)
    /// Example: $100 / (0.1 × 0.85) = $1,176.47
    ///
    /// When PAXG drops to this price, health factor = 1.0 and position gets liquidated
    static func calculateLiquidationPrice(
        collateralAmount: Decimal,
        debtValueUSD: Decimal,
        liquidationThreshold: Decimal
    ) -> Decimal {
        guard collateralAmount > 0 else { return 0 }
        guard liquidationThreshold > 0 else { return 0 }
        
        let denominator = collateralAmount * (liquidationThreshold / 100)
        return debtValueUSD / denominator
    }
    
    // MARK: - Available Additional Borrowing
    
    /// Calculate how much more user can borrow at current collateral
    /// - Parameters:
    ///   - collateralValueUSD: Total collateral value in USD
    ///   - currentDebtUSD: Current debt value in USD
    ///   - maxLTV: Maximum loan-to-value ratio (e.g., 75.0 = 75%)
    /// - Returns: Additional borrowable USD amount
    ///
    /// Formula: Available = (Collateral Value × Max LTV %) - Current Debt
    /// Example: ($418.30 × 0.75) - $100 = $213.73
    static func calculateAvailableToBorrow(
        collateralValueUSD: Decimal,
        currentDebtUSD: Decimal,
        maxLTV: Decimal
    ) -> Decimal {
        let maxDebtUSD = collateralValueUSD * (maxLTV / 100)
        let available = maxDebtUSD - currentDebtUSD
        return max(0, available)  // Never return negative
    }
    
    // MARK: - Interest Calculation (Simple)
    
    /// Calculate interest accrued over time (simple interest)
    /// - Parameters:
    ///   - principal: Borrowed amount
    ///   - apy: Annual percentage yield (e.g., 5.2 = 5.2%)
    ///   - days: Number of days
    /// - Returns: Interest amount
    ///
    /// Formula: Interest = Principal × (APY / 100) × (Days / 365)
    /// Example: $1000 × 0.052 × (30 / 365) = $4.27
    static func calculateSimpleInterest(
        principal: Decimal,
        apy: Decimal,
        days: Int
    ) -> Decimal {
        let dailyRate = (apy / 100) / 365
        return principal * dailyRate * Decimal(days)
    }
    
    // MARK: - Display Helpers
    
    /// Format health factor for display (handle infinity)
    /// - Parameter hf: Health factor value
    /// - Returns: Formatted string (e.g., "3.56", "∞", ">100")
    static func formatHealthFactor(_ hf: Decimal) -> String {
        if hf.isInfinite {
            return "∞"
        }
        if hf > 100 {
            return ">100"
        }
        return String(format: "%.2f", NSDecimalNumber(decimal: hf).doubleValue)
    }
    
    /// Format percentage with 1 decimal place
    /// - Parameter value: Percentage value (e.g., 75.5)
    /// - Returns: Formatted string (e.g., "75.5%")
    static func formatPercentage(_ value: Decimal) -> String {
        return String(format: "%.1f%%", NSDecimalNumber(decimal: value).doubleValue)
    }
    
    /// Format USD currency with 2 decimal places
    /// - Parameter value: USD amount
    /// - Returns: Formatted string (e.g., "$1,234.56")
    static func formatUSD(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Validation Helpers

extension BorrowCalculationEngine {
    
    /// Check if health factor is safe (>= 1.5)
    static func isSafeHealthFactor(_ hf: Decimal) -> Bool {
        return hf >= 1.5 || hf.isInfinite
    }
    
    /// Check if LTV is within safe limits (<= maxLTV)
    static func isSafeLTV(_ ltv: Decimal, maxLTV: Decimal) -> Bool {
        return ltv <= maxLTV
    }
    
    /// Get status color based on health factor
    /// - Parameter hf: Health factor
    /// - Returns: Color name ("green", "yellow", "red")
    static func healthFactorColor(_ hf: Decimal) -> String {
        if hf >= 2.0 || hf.isInfinite {
            return "green"
        } else if hf >= 1.5 {
            return "yellow"
        } else if hf >= 1.0 {
            return "orange"
        } else {
            return "red"
        }
    }
    
    /// Get status color based on LTV
    /// - Parameters:
    ///   - ltv: Current LTV
    ///   - maxLTV: Maximum allowed LTV
    /// - Returns: Color name ("green", "yellow", "red")
    static func ltvColor(_ ltv: Decimal, maxLTV: Decimal) -> String {
        if ltv < 50 {
            return "green"
        } else if ltv < 70 {
            return "yellow"
        } else if ltv <= maxLTV {
            return "orange"
        } else {
            return "red"
        }
    }
}

