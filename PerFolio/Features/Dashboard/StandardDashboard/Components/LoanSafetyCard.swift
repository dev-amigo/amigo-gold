import SwiftUI

/// Loan Safety Card - Color-coded safety indicator
struct LoanSafetyCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let loanRatioPercent: String
    let safetyStatus: SafetyStatus
    let maxSafeLTV: String
    
    var body: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(safetyColor)
                    
                    Text("Loan Safety")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Spacer()
                }
                
                // Loan Ratio (Large)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Loan Ratio:")
                        .font(.system(size: 16))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    
                    Text(loanRatioPercent)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(safetyColor)
                    
                    Text("%")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(safetyColor)
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(themeManager.perfolioTheme.border.opacity(0.3))
                                .frame(height: 12)
                                .cornerRadius(6)
                            
                            // Progress
                            Rectangle()
                                .fill(safetyColor)
                                .frame(
                                    width: min(
                                        geometry.size.width * (CGFloat(Double(loanRatioPercent) ?? 0) / 100),
                                        geometry.size.width
                                    ),
                                    height: 12
                                )
                                .cornerRadius(6)
                        }
                    }
                    .frame(height: 12)
                    
                    // Max reference
                    HStack {
                        Spacer()
                        Text("Max Safe: \(maxSafeLTV)%")
                            .font(.caption)
                            .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                    }
                }
                
                // Status Badge
                HStack(spacing: 8) {
                    Image(systemName: safetyIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(safetyColor)
                    
                    Text(safetyStatus.displayText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(safetyColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(safetyColor.opacity(0.15))
                .cornerRadius(12)
                
                // Safety Message
                Text(safetyStatus.message)
                    .font(.system(size: 15))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var safetyColor: Color {
        switch safetyStatus {
        case .verySafe:
            return themeManager.perfolioTheme.success
        case .caution:
            return Color.yellow
        case .warning:
            return Color.orange
        case .danger:
            return themeManager.perfolioTheme.danger
        }
    }
    
    private var safetyIcon: String {
        switch safetyStatus {
        case .verySafe:
            return "checkmark.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.octagon.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoanSafetyCard(
            loanRatioPercent: "22",
            safetyStatus: .verySafe,
            maxSafeLTV: "75"
        )
        
        LoanSafetyCard(
            loanRatioPercent: "55",
            safetyStatus: .caution,
            maxSafeLTV: "75"
        )
        
        LoanSafetyCard(
            loanRatioPercent: "74",
            safetyStatus: .warning,
            maxSafeLTV: "75"
        )
        
        LoanSafetyCard(
            loanRatioPercent: "88",
            safetyStatus: .danger,
            maxSafeLTV: "75"
        )
    }
    .environmentObject(ThemeManager())
    .padding()
}

