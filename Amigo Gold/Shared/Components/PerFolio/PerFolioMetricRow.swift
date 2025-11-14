import SwiftUI

/// Reusable key-value metric display row
struct PerFolioMetricRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let label: String
    private let value: String
    private let valueColor: Color?
    
    init(label: String, value: String, valueColor: Color? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(valueColor ?? themeManager.perfolioTheme.textPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PerFolioMetricRow(label: "LTV", value: "65%")
        PerFolioMetricRow(label: "Health Factor", value: "1.5", valueColor: .green)
        PerFolioMetricRow(label: "Liquidation Price", value: "$1,850")
    }
    .padding()
    .background(Color(hex: "1D1D1D"))
    .environmentObject(ThemeManager())
}

