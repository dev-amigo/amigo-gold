import SwiftUI

struct DepositBuyView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var inrAmount: String = ""
    @State private var selectedPaymentMethod: PaymentMethod = .upi
    
    enum PaymentMethod: String, CaseIterable {
        case upi = "UPI"
        case bankTransfer = "Bank Transfer"
        case card = "Card"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                buyWithINRCard
                goldPurchaseCard
                howItWorksCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(themeManager.perfolioTheme.primaryBackground.ignoresSafeArea())
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deposit & Buy")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
            
            Text("Fund your account and purchase gold")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Buy Crypto with INR
    
    private var buyWithINRCard: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 20) {
                PerFolioSectionHeader(
                    icon: "indianrupeesign.circle.fill",
                    title: "Buy Crypto with INR",
                    subtitle: "Use UPI, bank transfer, or card to purchase USDT"
                )
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Currency selectors (locked)
                lockedSelector(icon: "indianrupeesign", label: "Fiat Currency", value: "INR")
                lockedSelector(icon: "dollarsign.circle.fill", label: "Crypto", value: "USDT")
                
                // Amount input with presets
                PerFolioInputField(
                    label: "Amount",
                    text: $inrAmount,
                    leadingIcon: "indianrupeesign",
                    presetValues: ["₹500", "₹1000", "₹5000", "₹10000"]
                )
                
                // Payment method selector
                paymentMethodSelector
                
                // Get Quote button
                PerFolioButton("GET QUOTE") {
                    // Will be implemented in Phase 4
                }
                
                // Info banner
                PerFolioInfoBanner("Min: ₹500 • Max: ₹100,000")
            }
        }
    }
    
    private func lockedSelector(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
            }
            .padding(12)
            .background(themeManager.perfolioTheme.primaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
    
    private var paymentMethodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Method")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PerFolioPresetButton(
                        method.rawValue,
                        isSelected: selectedPaymentMethod == method
                    ) {
                        selectedPaymentMethod = method
                    }
                }
            }
        }
    }
    
    // MARK: - Gold Purchase Module
    
    private var goldPurchaseCard: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 16) {
                PerFolioSectionHeader(
                    icon: "circle.grid.cross.fill",
                    title: "Buy Gold (PAXG)",
                    subtitle: "Convert your USDT to tokenized gold"
                )
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Gold price display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Gold Price")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        Text("$0.00 / oz")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(themeManager.perfolioTheme.primaryBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                // Info banner
                PerFolioInfoBanner(
                    "Gold purchases are instant and backed 1:1 by physical gold"
                )
                
                // Coming soon button
                PerFolioButton("COMING SOON", style: .disabled, isDisabled: true) {
                    // Will be implemented in Phase 4
                }
            }
        }
    }
    
    // MARK: - How It Works
    
    private var howItWorksCard: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("How It Works")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    stepRow(number: "1", title: "Buy USDT", description: "Purchase USDT using INR via UPI or bank transfer")
                    stepRow(number: "2", title: "Swap for PAXG", description: "Convert USDT to tokenized gold (PAXG)")
                    stepRow(number: "3", title: "Use as Collateral", description: "Borrow against your gold holdings")
                }
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(themeManager.perfolioTheme.success)
                    Text("Powered by Privy & Ethereum")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
            }
        }
    }
    
    private func stepRow(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(themeManager.perfolioTheme.tintColor))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    DepositBuyView()
        .environmentObject(ThemeManager())
}
