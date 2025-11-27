import Foundation
import SwiftUI
import Combine

/// ViewModel for managing initial onboarding flow (notifications + currency selection)
@MainActor
final class InitialOnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentPage: Int = 0
    @Published var selectedCurrency: String = UserPreferences.defaultCurrency
    @Published var currencies: [Currency] = Currency.allCurrencies
    @Published var notificationPermissionGranted: Bool = false
    @Published var bellRotation: Double = 0
    @Published var isLoading: Bool = false
    
    // MARK: - Services
    
    private let notificationService = NotificationService.shared
    private let currencyService = CurrencyService.shared
    
    // MARK: - Callbacks
    
    var onComplete: (() -> Void)? = nil
    var onSkip: (() -> Void)? = nil
    
    // MARK: - Initialization
    
    init() {
        loadCurrencies()
    }
    
    // MARK: - Page Navigation
    
    func nextPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage += 1
        }
        HapticManager.shared.light()
    }
    
    func previousPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage -= 1
        }
        HapticManager.shared.light()
    }
    
    func skipToEnd() {
        // Mark onboarding as completed without completing steps
        if let email = UserPreferences.privyUserEmail {
            UserPreferences.setOnboardingCompleted(for: email)
        }
        onSkip?()
        AppLogger.log("⏭️ Onboarding skipped", category: "onboarding")
    }
    
    // MARK: - Notification Permission (Page 1)
    
    func requestNotificationPermission() async {
        isLoading = true
        
        let granted = await notificationService.requestPermission()
        notificationPermissionGranted = granted
        
        isLoading = false
        
        if granted {
            HapticManager.shared.success()
        }
        
        // Move to next page regardless of permission
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.nextPage()
        }
        
        AppLogger.log("✅ Notification permission: \(granted)", category: "onboarding")
    }
    
    func skipNotifications() {
        UserPreferences.notificationsEnabled = false
        nextPage()
        AppLogger.log("⏭️ Notifications skipped", category: "onboarding")
    }
    
    func startBellAnimation() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            bellRotation = 15
        }
    }
    
    // MARK: - Currency Selection (Page 2)
    
    func loadCurrencies() {
        currencies = Currency.allCurrencies
        
        // Fetch live rates in background
        Task {
            do {
                try await currencyService.fetchLiveExchangeRates()
                currencies = currencyService.supportedCurrencies
            } catch {
                AppLogger.log("⚠️ Failed to fetch live rates, using cached: \(error.localizedDescription)", category: "onboarding")
            }
        }
    }
    
    func selectCurrency(_ currencyCode: String) {
        selectedCurrency = currencyCode
        UserPreferences.defaultCurrency = currencyCode
        
        AppLogger.log("✅ Currency selected: \(currencyCode)", category: "onboarding")
    }
    
    func completeCurrencySelection() {
        // Save final currency selection
        UserPreferences.defaultCurrency = selectedCurrency
        
        // Mark onboarding as completed
        if let email = UserPreferences.privyUserEmail {
            UserPreferences.setOnboardingCompleted(for: email)
        }
        
        HapticManager.shared.success()
        
        // Complete onboarding
        onComplete?()
        
        AppLogger.log("🎉 Onboarding completed! Currency: \(selectedCurrency)", category: "onboarding")
    }
    
    // MARK: - Search & Filter
    
    func searchCurrencies(query: String) -> [Currency] {
        return currencyService.searchCurrencies(query: query)
    }
    
    func getPopularCurrencies() -> [Currency] {
        return currencies.filter { $0.isPopular }
    }
    
    func getCurrenciesByRegion(_ region: Currency.CurrencyRegion) -> [Currency] {
        return currencies.filter { $0.region == region }
    }
    
    // MARK: - Utilities
    
    func getConversionPreview(for currencyCode: String) -> String {
        guard let currency = Currency.getCurrency(code: currencyCode) else {
            return "1 USDC = 1.00"
        }
        let convertedAmount = currency.convertFromUSD(1.0)
        return "1 USDC = \(currency.format(convertedAmount))"
    }
}

