import SwiftUI

/// Second page of onboarding - select default currency
struct CurrencySelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: InitialOnboardingViewModel
    
    @State private var searchText = ""
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return viewModel.currencies
        } else {
            return viewModel.currencies.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.id.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var popularCurrencies: [Currency] {
        filteredCurrencies.filter { $0.isPopular }
    }
    
    var otherCurrencies: [Currency] {
        filteredCurrencies.filter { !$0.isPopular }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                // Currency Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "D4AF37").opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "D4AF37"), Color(hex: "FFD700")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 32)
                
                // Title
                Text("Choose Your Currency")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                
                // Subtitle
                Text("Display amounts in your preferred currency")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Search Bar
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
            .padding(12)
            .background(themeManager.perfolioTheme.secondaryBackground)
            .cornerRadius(10)
            .padding(.horizontal, 24)
            
            // Currency List
            ScrollView {
                VStack(spacing: 20) {
                    // Popular Currencies
                    if !popularCurrencies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Popular")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                                .padding(.horizontal, 24)
                            
                            ForEach(popularCurrencies) { currency in
                                OnboardingCurrencyRow(
                                    currency: currency,
                                    isSelected: viewModel.selectedCurrency == currency.id
                                ) {
                                    HapticManager.shared.light()
                                    viewModel.selectCurrency(currency.id)
                                }
                            }
                        }
                    }
                    
                    // Other Currencies
                    if !otherCurrencies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Currencies")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                                .padding(.horizontal, 24)
                            
                            ForEach(otherCurrencies) { currency in
                                OnboardingCurrencyRow(
                                    currency: currency,
                                    isSelected: viewModel.selectedCurrency == currency.id
                                ) {
                                    HapticManager.shared.light()
                                    viewModel.selectCurrency(currency.id)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.perfolioTheme.primaryBackground)
        .overlay(alignment: .bottom) {
            // Bottom bar with preview and continue button
            VStack(spacing: 12) {
                // Conversion preview
                if let currency = Currency.getCurrency(code: viewModel.selectedCurrency) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .foregroundStyle(Color(hex: "D4AF37"))
                        
                        Text("1 USDC ≈ \(currency.format(currency.convertFromUSD(1)))")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(themeManager.perfolioTheme.secondaryBackground)
                    .cornerRadius(8)
                }
                
                // Continue Button
                Button {
                    HapticManager.shared.medium()
                    viewModel.completeCurrencySelection()
                } label: {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "D4AF37"), Color(hex: "FFD700")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.black)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        themeManager.perfolioTheme.primaryBackground.opacity(0),
                        themeManager.perfolioTheme.primaryBackground,
                        themeManager.perfolioTheme.primaryBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Onboarding Currency Row

struct OnboardingCurrencyRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currency: Currency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Flag
                Text(currency.flag)
                    .font(.system(size: 32))
                
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
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: "D4AF37"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                isSelected ?
                    themeManager.perfolioTheme.secondaryBackground.opacity(0.6) :
                    Color.clear
            )
        }
    }
}

// MARK: - Preview
// Preview temporarily disabled

