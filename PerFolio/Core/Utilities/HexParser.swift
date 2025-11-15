import Foundation

/// Safe hex string parsing utilities for large numbers
enum HexParser {
    
    enum ParsingError: Error {
        case invalidHexString
        case numberTooLarge
        case negativeNumber
    }
    
    /// Safely parse hex string to Decimal (supports very large numbers)
    /// - Parameter hexString: Hex string with or without "0x" prefix
    /// - Returns: Decimal value
    static func parseToDecimal(_ hexString: String) throws -> Decimal {
        let cleaned = hexString.replacingOccurrences(of: "0x", with: "")
        
        guard !cleaned.isEmpty else {
            throw ParsingError.invalidHexString
        }
        
        // Check if it's a valid hex string
        let hexCharSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        guard cleaned.rangeOfCharacter(from: hexCharSet.inverted) == nil else {
            throw ParsingError.invalidHexString
        }
        
        // For small numbers (< 64 bits), use Int for efficiency
        if cleaned.count <= 16 {
            guard let intValue = Int(cleaned, radix: 16) else {
                throw ParsingError.invalidHexString
            }
            return Decimal(intValue)
        }
        
        // For large numbers, parse digit by digit
        var result = Decimal(0)
        let base = Decimal(16)
        
        for char in cleaned {
            guard let digit = Int(String(char), radix: 16) else {
                throw ParsingError.invalidHexString
            }
            
            result = result * base + Decimal(digit)
            
            // Safety check to prevent overflow
            if result.isNaN || result.isInfinite {
                throw ParsingError.numberTooLarge
            }
        }
        
        return result
    }
    
    /// Parse hex string to Int64 (for smaller numbers)
    /// - Parameter hexString: Hex string with or without "0x" prefix
    /// - Returns: Int64 value
    static func parseToInt64(_ hexString: String) throws -> Int64 {
        let cleaned = hexString.replacingOccurrences(of: "0x", with: "")
        
        guard !cleaned.isEmpty else {
            throw ParsingError.invalidHexString
        }
        
        guard let value = Int64(cleaned, radix: 16) else {
            throw ParsingError.invalidHexString
        }
        
        return value
    }
    
    /// Convert Decimal to hex string
    /// - Parameter value: Decimal value
    /// - Returns: Hex string with "0x" prefix
    static func decimalToHex(_ value: Decimal) -> String {
        let nsNumber = value as NSNumber
        let intValue = nsNumber.int64Value
        return "0x" + String(intValue, radix: 16)
    }
}

