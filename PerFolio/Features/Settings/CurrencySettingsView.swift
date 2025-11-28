import SwiftUI

/// View for selecting default currency in settings
struct CurrencySettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var currencyService = CurrencyService.shared
    @State private var searchText = ""
    @State private var selectedCurrency = UserPreferences.defaultCurrency
    @State private var isRefreshing = false
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return currencyService.supportedCurrencies
        } else {
            return currencyService.searchCurrencies(query: searchText)
        }
    }
    
    var popularCurrencies: [Currency] {
        filteredCurrencies.filter { $0.isPopular }
    }
    
    var otherCurrencies: [Currency] {
        filteredCurrencies.filter { !$0.isPopular }
    }
    
    var body: some View {
        List {
            // Search Bar
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                    
                    TextField("Search currencies...", text: $searchText)
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            HapticManager.shared.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                        }
                    }
                }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            
            // Popular Currencies
            if !popularCurrencies.isEmpty {
                Section {
                    ForEach(popularCurrencies) { currency in
                        SettingsCurrencyRow(
                            currency: currency,
                            isSelected: selectedCurrency == currency.id
                        ) {
                            selectCurrency(currency.id)
                        }
                    }
                } header: {
                    Text("Popular")
                }
                .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            }
            
            // All Currencies
            if !otherCurrencies.isEmpty {
                Section {
                    ForEach(otherCurrencies) { currency in
                        SettingsCurrencyRow(
                            currency: currency,
                            isSelected: selectedCurrency == currency.id
                        ) {
                            selectCurrency(currency.id)
                        }
                    }
                } header: {
                    Text("All Currencies")
                }
                .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.perfolioTheme.primaryBackground)
        .navigationTitle("Default Currency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isRefreshing {
                    ProgressView()
                        .tint(themeManager.perfolioTheme.textPrimary)
                } else {
                    Button {
                        refreshRates()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            // Fetch live rates on appear
            refreshRates()
        }
    }
    
    private func selectCurrency(_ currencyCode: String) {
        selectedCurrency = currencyCode
        UserPreferences.defaultCurrency = currencyCode
        HapticManager.shared.success()
        
        // Optionally auto-dismiss after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
        
        AppLogger.log("✅ Currency updated to: \(currencyCode)", category: "settings")
    }
    
    private func refreshRates() {
        isRefreshing = true
        Task {
            do {
                try await currencyService.fetchLiveExchangeRates()
                isRefreshing = false
                HapticManager.shared.success()
            } catch {
                isRefreshing = false
                AppLogger.log("⚠️ Failed to refresh rates: \(error.localizedDescription)", category: "settings")
            }
        }
    }
}

// MARK: - Settings Currency Row

struct SettingsCurrencyRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currency: Currency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Flag
                Text(currency.flag)
                    .font(.system(size: 28))
                
                // Currency info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.id)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Text(currency.name)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
                
                Spacer()
                
                // Symbol
                Text(currency.symbol)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "D4AF37"))
                }
            }
        }
    }
}

// MARK: - Preview
// Preview temporarily disabled

