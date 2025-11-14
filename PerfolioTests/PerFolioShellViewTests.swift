import XCTest
import SwiftUI
@testable import Amigo_Gold

final class PerFolioShellViewTests: XCTestCase {
    
    func testTabEnumRawValues() {
        // Test that tab enum raw values are sequential
        XCTAssertEqual(PerFolioShellView.PerFolioTab.dashboard.rawValue, 0)
        XCTAssertEqual(PerFolioShellView.PerFolioTab.depositBuy.rawValue, 1)
        XCTAssertEqual(PerFolioShellView.PerFolioTab.withdraw.rawValue, 2)
    }
    
    func testTabTitles() {
        // Test tab titles
        XCTAssertEqual(PerFolioShellView.PerFolioTab.dashboard.title, "Dashboard")
        XCTAssertEqual(PerFolioShellView.PerFolioTab.depositBuy.title, "Deposit & Buy")
        XCTAssertEqual(PerFolioShellView.PerFolioTab.withdraw.title, "Withdraw")
    }
    
    func testTabSystemImages() {
        // Test tab system image names
        XCTAssertEqual(PerFolioShellView.PerFolioTab.dashboard.systemImage, "chart.pie.fill")
        XCTAssertEqual(PerFolioShellView.PerFolioTab.depositBuy.systemImage, "arrow.left.arrow.right")
        XCTAssertEqual(PerFolioShellView.PerFolioTab.withdraw.systemImage, "arrow.up.circle.fill")
    }
    
    func testAllTabsCaseIterable() {
        // Test that all tabs are included in CaseIterable
        let allTabs = PerFolioShellView.PerFolioTab.allCases
        XCTAssertEqual(allTabs.count, 3)
        XCTAssertTrue(allTabs.contains(.dashboard))
        XCTAssertTrue(allTabs.contains(.depositBuy))
        XCTAssertTrue(allTabs.contains(.withdraw))
    }
    
    func testTabInitFromRawValue() {
        // Test tab initialization from raw value
        XCTAssertEqual(PerFolioShellView.PerFolioTab(rawValue: 0), .dashboard)
        XCTAssertEqual(PerFolioShellView.PerFolioTab(rawValue: 1), .depositBuy)
        XCTAssertEqual(PerFolioShellView.PerFolioTab(rawValue: 2), .withdraw)
        XCTAssertNil(PerFolioShellView.PerFolioTab(rawValue: 999))
    }
}

// MARK: - Deposit & Buy View Tests

final class DepositBuyViewTests: XCTestCase {
    
    func testPaymentMethodEnum() {
        // Test payment method enum values
        XCTAssertEqual(DepositBuyView.PaymentMethod.upi.rawValue, "UPI")
        XCTAssertEqual(DepositBuyView.PaymentMethod.bankTransfer.rawValue, "Bank Transfer")
        XCTAssertEqual(DepositBuyView.PaymentMethod.card.rawValue, "Card")
    }
    
    func testPaymentMethodCaseIterable() {
        // Test that all payment methods are included
        let allMethods = DepositBuyView.PaymentMethod.allCases
        XCTAssertEqual(allMethods.count, 3)
        XCTAssertTrue(allMethods.contains(.upi))
        XCTAssertTrue(allMethods.contains(.bankTransfer))
        XCTAssertTrue(allMethods.contains(.card))
    }
}

// MARK: - Theme Manager Tests

@MainActor
final class ThemeManagerTests: XCTestCase {
    
    func testThemeManagerInitialization() {
        let themeManager = ThemeManager()
        
        // Test default initialization
        XCTAssertEqual(themeManager.colorScheme, .dark)
        XCTAssertNotNil(themeManager.perfolioTheme)
        XCTAssertNotNil(themeManager.typography)
    }
    
    func testToggleScheme() {
        let themeManager = ThemeManager()
        
        // Initial state
        XCTAssertEqual(themeManager.colorScheme, .dark)
        
        // Toggle to light
        themeManager.toggleScheme()
        XCTAssertEqual(themeManager.colorScheme, .light)
        
        // Toggle back to dark
        themeManager.toggleScheme()
        XCTAssertEqual(themeManager.colorScheme, .dark)
    }
    
    func testUpdateColorScheme() {
        let themeManager = ThemeManager()
        
        // Update to light
        themeManager.updateColorScheme(.light)
        XCTAssertEqual(themeManager.colorScheme, .light)
        
        // Update back to dark
        themeManager.updateColorScheme(.dark)
        XCTAssertEqual(themeManager.colorScheme, .dark)
        
        // Update to same scheme (should not change)
        themeManager.updateColorScheme(.dark)
        XCTAssertEqual(themeManager.colorScheme, .dark)
    }
    
    func testPerFolioThemeIsGold() {
        let themeManager = ThemeManager()
        
        // PerFolio theme should always be .gold
        XCTAssertEqual(themeManager.perfolioTheme.tintColor, PerFolioTheme.gold.tintColor)
        XCTAssertEqual(themeManager.perfolioTheme.buttonBackground, PerFolioTheme.gold.buttonBackground)
    }
}

