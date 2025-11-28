import SwiftUI

/// Collateral Overview Card - "Your Gold" section
struct CollateralOverviewCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let paxgBalance: Decimal
    let totalValue: String
    let todayChange: String
    let todayChangePercent: String
    let isPositiveChange: Bool
    let goldPrice: String
    
    var body: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    
                    Text("Your Gold")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                }
                
                // Main Value (Goldish color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(totalValue)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    
                    Text("\(formatDecimal(paxgBalance)) PAXG")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Today's Change
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Change")
                            .font(.caption)
                            .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isPositiveChange ? themeManager.perfolioTheme.success : themeManager.perfolioTheme.danger)
                            
                            Text(isPositiveChange ? "+\(todayChange)" : "-\(todayChange)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(isPositiveChange ? themeManager.perfolioTheme.success : themeManager.perfolioTheme.danger)
                            
                            Text("(\(isPositiveChange ? "+" : "-")\(todayChangePercent)%)")
                                .font(.system(size: 14))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Gold Price
                HStack(spacing: 8) {
                    Text("Gold Price:")
                        .font(.system(size: 15))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    
                    Text("\(goldPrice)/oz")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isPositiveChange ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isPositiveChange ? themeManager.perfolioTheme.success : themeManager.perfolioTheme.danger)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
        }
    }
    
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        return formatter.string(from: value as NSDecimalNumber) ?? "0"
    }
}

#Preview {
    CollateralOverviewCard(
        paxgBalance: 1.24,
        totalValue: "₹1,24,580",
        todayChange: "₹320",
        todayChangePercent: "0.26",
        isPositiveChange: true,
        goldPrice: "₹1,00,510"
    )
    .environmentObject(ThemeManager())
    .padding()
}

