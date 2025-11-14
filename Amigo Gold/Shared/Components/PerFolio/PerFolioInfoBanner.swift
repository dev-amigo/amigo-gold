import SwiftUI

/// Reusable info/warning banner component
struct PerFolioInfoBanner: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let message: String
    private let style: BannerStyle
    
    enum BannerStyle {
        case info       // Gold background
        case success    // Green tint
        case warning    // Yellow tint
        case danger     // Red tint
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.circle.fill"
            }
        }
    }
    
    init(_ message: String, style: BannerStyle = .info) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(iconColor)
            
            Text(message)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private var iconColor: Color {
        switch style {
        case .info:
            return themeManager.perfolioTheme.tintColor
        case .success:
            return themeManager.perfolioTheme.success
        case .warning:
            return themeManager.perfolioTheme.warning
        case .danger:
            return themeManager.perfolioTheme.danger
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .info:
            return themeManager.perfolioTheme.tintColor.opacity(0.1)
        case .success:
            return themeManager.perfolioTheme.success.opacity(0.1)
        case .warning:
            return themeManager.perfolioTheme.warning.opacity(0.1)
        case .danger:
            return themeManager.perfolioTheme.danger.opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PerFolioInfoBanner(
            "Gold purchases are instant and backed 1:1 by physical gold",
            style: .info
        )
        
        PerFolioInfoBanner(
            "Transaction confirmed successfully",
            style: .success
        )
        
        PerFolioInfoBanner(
            "Your health factor is approaching liquidation threshold",
            style: .warning
        )
        
        PerFolioInfoBanner(
            "Insufficient balance to complete this transaction",
            style: .danger
        )
    }
    .padding()
    .background(Color(hex: "1D1D1D"))
    .environmentObject(ThemeManager())
}

