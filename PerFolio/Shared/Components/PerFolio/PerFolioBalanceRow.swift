import SwiftUI

/// Reusable balance display row for tokens
struct PerFolioBalanceRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let tokenSymbol: String
    private let tokenAmount: String
    private let usdValue: String
    private let isLoading: Bool
    
    init(
        tokenSymbol: String,
        tokenAmount: String,
        usdValue: String,
        isLoading: Bool = false
    ) {
        self.tokenSymbol = tokenSymbol
        self.tokenAmount = tokenAmount
        self.usdValue = usdValue
        self.isLoading = isLoading
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tokenSymbol)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(tokenAmount)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                }
            }
            
            Spacer()
            
            if !isLoading {
                Text(usdValue)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PerFolioBalanceRow(
            tokenSymbol: "PAXG",
            tokenAmount: "2.45",
            usdValue: "$4,850.00"
        )
        
        PerFolioBalanceRow(
            tokenSymbol: "USDC",
            tokenAmount: "0.00",
            usdValue: "$0.00",
            isLoading: true
        )
    }
    .padding()
    .background(Color(hex: "242424"))
    .environmentObject(ThemeManager())
}
