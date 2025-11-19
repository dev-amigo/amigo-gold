import SwiftUI

/// Reusable section header with icon and title
struct PerFolioSectionHeader: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let icon: String
    private let title: String
    private let subtitle: String?
    
    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: subtitle != nil ? 8 : 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
            }
            
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PerFolioSectionHeader(
            icon: "bitcoinsign.circle.fill",
            title: "Your Gold Holdings"
        )
        
        PerFolioSectionHeader(
            icon: "indianrupeesign.circle.fill",
            title: "Buy Crypto with INR",
            subtitle: "Use UPI, bank transfer, or card to purchase USDC"
        )
    }
    .padding()
    .background(Color(hex: "1D1D1D"))
    .environmentObject(ThemeManager())
}
