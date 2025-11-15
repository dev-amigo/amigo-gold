import Foundation

/// Reusable currency and decimal formatting utilities
enum CurrencyFormatter {
    
    // MARK: - Decimal Formatting
    
    /// Format decimal with flexible precision (2-6 decimals)
    static func formatDecimal(_ value: Decimal, minDecimals: Int = 2, maxDecimals: Int = 6) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minDecimals
        formatter.maximumFractionDigits = maxDecimals
        formatter.usesGroupingSeparator = true
        return formatter.string(from: value as NSNumber) ?? "0"
    }
    
    /// Format currency (INR)
    static func formatINR(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return "₹\(formatter.string(from: value as NSNumber) ?? "0")"
    }
    
    /// Format USD currency
    static func formatUSD(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }
    
    /// Format token amount with symbol
    static func formatToken(_ value: Decimal, symbol: String, maxDecimals: Int = 6) -> String {
        let formattedValue = formatDecimal(value, minDecimals: 2, maxDecimals: maxDecimals)
        return "\(formattedValue) \(symbol)"
    }
    
    // MARK: - Amount Parsing
    
    /// Parse INR amount string (removes ₹, commas, spaces)
    static func parseINRAmount(_ amount: String) -> Decimal? {
        let cleaned = amount
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned)
    }
    
    /// Parse decimal amount string (removes commas, spaces)
    static func parseDecimalAmount(_ amount: String) -> Decimal? {
        let cleaned = amount
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned)
    }
    
    // MARK: - Validation
    
    /// Validate amount is within range
    static func validateAmount(_ amount: Decimal, min: Decimal, max: Decimal) -> Bool {
        return amount >= min && amount <= max && amount > 0
    }
}

