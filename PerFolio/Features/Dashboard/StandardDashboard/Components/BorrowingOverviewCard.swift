import SwiftUI

/// Borrowing Overview Card - "Your Loan" section
struct BorrowingOverviewCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let borrowedAmount: String
    let totalOwed: String
    let interestRate: String
    let onRepayTap: () -> Void
    
    var body: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.purple)
                    
                    Text("Your Loan")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                }
                
                // Borrowed Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Borrowed")
                        .font(.caption)
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                    
                    Text(borrowedAmount)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                }
                
                // Total Owed
                VStack(alignment: .leading, spacing: 8) {
                    Text("You Owe")
                        .font(.caption)
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                    
                    Text(totalOwed)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.danger)
                }
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Interest Rate
                HStack {
                    Text("Interest Rate:")
                        .font(.system(size: 15))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    
                    Text("\(interestRate)% APY")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                }
                
                // Repay Button
                PerFolioButton("Repay Now") {
                    HapticManager.shared.medium()
                    onRepayTap()
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    BorrowingOverviewCard(
        borrowedAmount: "₹80,250",
        totalOwed: "₹80,725",
        interestRate: "7.0",
        onRepayTap: {}
    )
    .environmentObject(ThemeManager())
    .padding()
}

