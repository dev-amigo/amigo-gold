import SwiftUI

/// Available to Borrow Card - Shows borrowing capacity
struct AvailableToBorrowCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let availableAmount: String
    let onBorrowTap: () -> Void
    
    var body: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.blue)
                    
                    Text("Available to Borrow")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                }
                
                // Description
                Text("You can safely borrow up to:")
                    .font(.system(size: 15))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                
                // Amount (Large, prominent)
                Text(availableAmount)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                
                // Caption
                Text("(based on your gold value)")
                    .font(.caption)
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                
                // Borrow Button
                PerFolioButton("Borrow Now") {
                    HapticManager.shared.medium()
                    onBorrowTap()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    AvailableToBorrowCard(
        availableAmount: "₹14,750",
        onBorrowTap: {}
    )
    .environmentObject(ThemeManager())
    .padding()
}

