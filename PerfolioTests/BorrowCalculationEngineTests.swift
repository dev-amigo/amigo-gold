import XCTest
@testable import PerFolio

/// Unit tests for BorrowCalculationEngine
/// Tests all core formulas against known values from web app
final class BorrowCalculationEngineTests: XCTestCase {
    
    // MARK: - Test Data (from web app examples)
    
    let paxgPrice: Decimal = 4183.0  // $4,183/oz
    let collateralAmount: Decimal = 0.1  // 0.1 PAXG
    let borrowAmount: Decimal = 100.0  // $100 USDC
    let maxLTV: Decimal = 75.0  // 75%
    let liquidationThreshold: Decimal = 85.0  // 85%
    
    var collateralValueUSD: Decimal {
        return collateralAmount * paxgPrice  // $418.30
    }
    
    // MARK: - Max Borrow Tests
    
    func testCalculateMaxBorrow() {
        let result = BorrowCalculationEngine.calculateMaxBorrow(
            collateralAmount: collateralAmount,
            paxgPrice: paxgPrice,
            maxLTV: maxLTV
        )
        
        // Expected: 0.1 × $4,183 × 0.75 = $313.725
        XCTAssertEqual(result, 313.725, accuracy: 0.01, "Max borrow calculation incorrect")
    }
    
    func testCalculateMaxBorrowZeroCollateral() {
        let result = BorrowCalculationEngine.calculateMaxBorrow(
            collateralAmount: 0,
            paxgPrice: paxgPrice,
            maxLTV: maxLTV
        )
        
        XCTAssertEqual(result, 0, "Max borrow should be 0 for zero collateral")
    }
    
    func testCalculateMaxBorrowDifferentLTV() {
        let result = BorrowCalculationEngine.calculateMaxBorrow(
            collateralAmount: 1.0,  // 1 PAXG
            paxgPrice: 4000.0,
            maxLTV: 50.0  // 50% LTV
        )
        
        // Expected: 1.0 × $4,000 × 0.50 = $2,000
        XCTAssertEqual(result, 2000.0, accuracy: 0.01, "Max borrow at 50% LTV incorrect")
    }
    
    // MARK: - Health Factor Tests
    
    func testCalculateHealthFactor() {
        let result = BorrowCalculationEngine.calculateHealthFactor(
            collateralValueUSD: collateralValueUSD,  // $418.30
            debtValueUSD: borrowAmount,  // $100
            liquidationThreshold: liquidationThreshold  // 85%
        )
        
        // Expected: ($418.30 × 0.85) / $100 = 3.56
        XCTAssertEqual(result, 3.5555, accuracy: 0.01, "Health factor calculation incorrect")
    }
    
    func testCalculateHealthFactorNoDebt() {
        let result = BorrowCalculationEngine.calculateHealthFactor(
            collateralValueUSD: collateralValueUSD,
            debtValueUSD: 0,
            liquidationThreshold: liquidationThreshold
        )
        
        XCTAssertEqual(result, Decimal.infinity, "Health factor should be infinity with no debt")
    }
    
    func testCalculateHealthFactorNoCollateral() {
        let result = BorrowCalculationEngine.calculateHealthFactor(
            collateralValueUSD: 0,
            debtValueUSD: borrowAmount,
            liquidationThreshold: liquidationThreshold
        )
        
        XCTAssertEqual(result, 0, "Health factor should be 0 with no collateral")
    }
    
    func testCalculateHealthFactorAtLiquidation() {
        // Exactly at liquidation threshold
        let collateralValue: Decimal = 117.65  // Chosen to make HF = 1.0
        let debt: Decimal = 100.0
        
        let result = BorrowCalculationEngine.calculateHealthFactor(
            collateralValueUSD: collateralValue,
            debtValueUSD: debt,
            liquidationThreshold: liquidationThreshold
        )
        
        // Expected: (117.65 × 0.85) / 100 = 1.00
        XCTAssertEqual(result, 1.00, accuracy: 0.01, "Health factor at liquidation should be 1.0")
    }
    
    // MARK: - LTV Tests
    
    func testCalculateCurrentLTV() {
        let result = BorrowCalculationEngine.calculateCurrentLTV(
            collateralValueUSD: collateralValueUSD,  // $418.30
            debtValueUSD: borrowAmount  // $100
        )
        
        // Expected: ($100 / $418.30) × 100 = 23.9%
        XCTAssertEqual(result, 23.9, accuracy: 0.1, "LTV calculation incorrect")
    }
    
    func testCalculateCurrentLTVZeroCollateral() {
        let result = BorrowCalculationEngine.calculateCurrentLTV(
            collateralValueUSD: 0,
            debtValueUSD: borrowAmount
        )
        
        XCTAssertEqual(result, 0, "LTV should be 0 for zero collateral")
    }
    
    func testCalculateCurrentLTVAtMax() {
        let result = BorrowCalculationEngine.calculateCurrentLTV(
            collateralValueUSD: 1000.0,
            debtValueUSD: 750.0  // 75% of collateral
        )
        
        // Expected: (750 / 1000) × 100 = 75%
        XCTAssertEqual(result, 75.0, accuracy: 0.01, "LTV at max should be 75%")
    }
    
    // MARK: - Liquidation Price Tests
    
    func testCalculateLiquidationPrice() {
        let result = BorrowCalculationEngine.calculateLiquidationPrice(
            collateralAmount: collateralAmount,  // 0.1 PAXG
            debtValueUSD: borrowAmount,  // $100
            liquidationThreshold: liquidationThreshold  // 85%
        )
        
        // Expected: $100 / (0.1 × 0.85) = $1,176.47
        XCTAssertEqual(result, 1176.47, accuracy: 0.01, "Liquidation price calculation incorrect")
    }
    
    func testCalculateLiquidationPriceZeroCollateral() {
        let result = BorrowCalculationEngine.calculateLiquidationPrice(
            collateralAmount: 0,
            debtValueUSD: borrowAmount,
            liquidationThreshold: liquidationThreshold
        )
        
        XCTAssertEqual(result, 0, "Liquidation price should be 0 for zero collateral")
    }
    
    func testCalculateLiquidationPriceHighDebt() {
        let result = BorrowCalculationEngine.calculateLiquidationPrice(
            collateralAmount: 1.0,  // 1 PAXG
            debtValueUSD: 3000.0,  // $3000 debt
            liquidationThreshold: liquidationThreshold
        )
        
        // Expected: $3000 / (1.0 × 0.85) = $3,529.41
        XCTAssertEqual(result, 3529.41, accuracy: 0.01, "Liquidation price for high debt incorrect")
    }
    
    // MARK: - Available to Borrow Tests
    
    func testCalculateAvailableToBorrow() {
        let result = BorrowCalculationEngine.calculateAvailableToBorrow(
            collateralValueUSD: collateralValueUSD,  // $418.30
            currentDebtUSD: borrowAmount,  // $100
            maxLTV: maxLTV  // 75%
        )
        
        // Expected: ($418.30 × 0.75) - $100 = $213.725
        XCTAssertEqual(result, 213.725, accuracy: 0.01, "Available to borrow calculation incorrect")
    }
    
    func testCalculateAvailableToBorrowAtMax() {
        let result = BorrowCalculationEngine.calculateAvailableToBorrow(
            collateralValueUSD: 1000.0,
            currentDebtUSD: 750.0,  // Already at max
            maxLTV: maxLTV
        )
        
        XCTAssertEqual(result, 0, "Available should be 0 when at max LTV")
    }
    
    func testCalculateAvailableToBorrowOverMax() {
        let result = BorrowCalculationEngine.calculateAvailableToBorrow(
            collateralValueUSD: 1000.0,
            currentDebtUSD: 800.0,  // Over max (80% > 75%)
            maxLTV: maxLTV
        )
        
        XCTAssertEqual(result, 0, "Available should be 0 (not negative) when over max LTV")
    }
    
    // MARK: - Interest Calculation Tests
    
    func testCalculateSimpleInterest() {
        let result = BorrowCalculationEngine.calculateSimpleInterest(
            principal: 1000.0,  // $1000
            apy: 5.2,  // 5.2%
            days: 30  // 30 days
        )
        
        // Expected: $1000 × 0.052 × (30/365) = $4.27
        XCTAssertEqual(result, 4.27, accuracy: 0.01, "Simple interest calculation incorrect")
    }
    
    func testCalculateSimpleInterestOneYear() {
        let result = BorrowCalculationEngine.calculateSimpleInterest(
            principal: 1000.0,
            apy: 5.2,
            days: 365
        )
        
        // Expected: $1000 × 0.052 = $52.00
        XCTAssertEqual(result, 52.00, accuracy: 0.01, "One year interest incorrect")
    }
    
    func testCalculateSimpleInterestZeroDays() {
        let result = BorrowCalculationEngine.calculateSimpleInterest(
            principal: 1000.0,
            apy: 5.2,
            days: 0
        )
        
        XCTAssertEqual(result, 0, "Interest for 0 days should be 0")
    }
    
    // MARK: - Format Tests
    
    func testFormatHealthFactor() {
        XCTAssertEqual(BorrowCalculationEngine.formatHealthFactor(3.56), "3.56")
        XCTAssertEqual(BorrowCalculationEngine.formatHealthFactor(1.00), "1.00")
        XCTAssertEqual(BorrowCalculationEngine.formatHealthFactor(Decimal.infinity), "∞")
        XCTAssertEqual(BorrowCalculationEngine.formatHealthFactor(150.5), ">100")
    }
    
    func testFormatPercentage() {
        XCTAssertEqual(BorrowCalculationEngine.formatPercentage(75.5), "75.5%")
        XCTAssertEqual(BorrowCalculationEngine.formatPercentage(0.0), "0.0%")
        XCTAssertEqual(BorrowCalculationEngine.formatPercentage(100.0), "100.0%")
    }
    
    func testFormatUSD() {
        let result = BorrowCalculationEngine.formatUSD(1234.56)
        XCTAssertTrue(result.contains("1,234.56"), "USD format should include thousands separator")
    }
    
    // MARK: - Validation Tests
    
    func testIsSafeHealthFactor() {
        XCTAssertTrue(BorrowCalculationEngine.isSafeHealthFactor(1.5), "HF 1.5 should be safe")
        XCTAssertTrue(BorrowCalculationEngine.isSafeHealthFactor(2.0), "HF 2.0 should be safe")
        XCTAssertTrue(BorrowCalculationEngine.isSafeHealthFactor(Decimal.infinity), "Infinite HF should be safe")
        XCTAssertFalse(BorrowCalculationEngine.isSafeHealthFactor(1.4), "HF 1.4 should not be safe")
        XCTAssertFalse(BorrowCalculationEngine.isSafeHealthFactor(1.0), "HF 1.0 should not be safe")
    }
    
    func testIsSafeLTV() {
        XCTAssertTrue(BorrowCalculationEngine.isSafeLTV(50.0, maxLTV: 75.0), "50% LTV should be safe")
        XCTAssertTrue(BorrowCalculationEngine.isSafeLTV(75.0, maxLTV: 75.0), "75% LTV at max should be safe")
        XCTAssertFalse(BorrowCalculationEngine.isSafeLTV(76.0, maxLTV: 75.0), "76% LTV should not be safe")
        XCTAssertFalse(BorrowCalculationEngine.isSafeLTV(100.0, maxLTV: 75.0), "100% LTV should not be safe")
    }
    
    func testHealthFactorColor() {
        XCTAssertEqual(BorrowCalculationEngine.healthFactorColor(2.0), "green")
        XCTAssertEqual(BorrowCalculationEngine.healthFactorColor(1.5), "yellow")
        XCTAssertEqual(BorrowCalculationEngine.healthFactorColor(1.2), "orange")
        XCTAssertEqual(BorrowCalculationEngine.healthFactorColor(0.9), "red")
        XCTAssertEqual(BorrowCalculationEngine.healthFactorColor(Decimal.infinity), "green")
    }
    
    func testLTVColor() {
        XCTAssertEqual(BorrowCalculationEngine.ltvColor(40.0, maxLTV: 75.0), "green")
        XCTAssertEqual(BorrowCalculationEngine.ltvColor(60.0, maxLTV: 75.0), "yellow")
        XCTAssertEqual(BorrowCalculationEngine.ltvColor(72.0, maxLTV: 75.0), "orange")
        XCTAssertEqual(BorrowCalculationEngine.ltvColor(80.0, maxLTV: 75.0), "red")
    }
}

