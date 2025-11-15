import Foundation

/// Request model for creating a new borrow position
/// Contains all parameters needed to execute a borrow transaction
struct BorrowRequest {
    
    // MARK: - Input Amounts (in token units)
    
    /// Amount of PAXG to deposit as collateral (in token units, not Wei)
    let collateralAmount: Decimal
    
    /// Amount of USDC to borrow (in token units, not smallest units)
    let borrowAmount: Decimal
    
    // MARK: - Addresses
    
    /// User's wallet address
    let userAddress: String
    
    /// Fluid vault contract address
    let vaultAddress: String
    
    // MARK: - Validation
    
    /// Check if request is valid (non-zero amounts, valid addresses)
    var isValid: Bool {
        return collateralAmount > 0 &&
               borrowAmount > 0 &&
               !userAddress.isEmpty &&
               !vaultAddress.isEmpty &&
               userAddress.hasPrefix("0x") &&
               vaultAddress.hasPrefix("0x")
    }
}

// MARK: - Wei Conversion Helpers

extension BorrowRequest {
    
    /// Convert collateral amount to Wei (18 decimals for PAXG)
    /// - Returns: Collateral in Wei as hex string
    func collateralInWei() -> String {
        let weiValue = collateralAmount * pow(Decimal(10), 18)
        let intValue = NSDecimalNumber(decimal: weiValue).intValue
        return "0x" + String(intValue, radix: 16)
    }
    
    /// Convert borrow amount to smallest unit (6 decimals for USDC)
    /// - Returns: Borrow amount in smallest units as hex string
    func borrowInSmallestUnit() -> String {
        let smallestUnit = borrowAmount * pow(Decimal(10), 6)
        let intValue = NSDecimalNumber(decimal: smallestUnit).intValue
        return "0x" + String(intValue, radix: 16)
    }
}

// MARK: - Mock Data (for development)

extension BorrowRequest {
    static var mock: BorrowRequest {
        return BorrowRequest(
            collateralAmount: 0.1,  // 0.1 PAXG (~$418)
            borrowAmount: 100.0,    // $100 USDC (52% LTV)
            userAddress: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            vaultAddress: ContractAddresses.fluidPaxgUsdcVault
        )
    }
}

