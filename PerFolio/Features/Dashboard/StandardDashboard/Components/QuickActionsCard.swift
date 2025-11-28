import SwiftUI

/// Quick Actions Card - Big action buttons
struct QuickActionsCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let onBorrowMore: () -> Void
    let onAddGold: () -> Void
    let onRepayLoan: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Borrow More
            Button {
                HapticManager.shared.medium()
                onBorrowMore()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    
                    Text("Borrow More")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(themeManager.perfolioTheme.secondaryBackground)
                .cornerRadius(16)
            }
            
            // Add Gold
            Button {
                HapticManager.shared.medium()
                onAddGold()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    
                    Text("Add Gold")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(themeManager.perfolioTheme.secondaryBackground)
                .cornerRadius(16)
            }
            
            // Repay Loan
            Button {
                HapticManager.shared.medium()
                onRepayLoan()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.purple)
                    
                    Text("Repay Loan")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(themeManager.perfolioTheme.secondaryBackground)
                .cornerRadius(16)
            }
        }
    }
}

#Preview {
    QuickActionsCard(
        onBorrowMore: {},
        onAddGold: {},
        onRepayLoan: {}
    )
    .environmentObject(ThemeManager())
    .padding()
}

