import SwiftUI

/// Reusable preset/quick selection button (for amounts, percentages, etc.)
struct PerFolioPresetButton: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void
    
    init(_ title: String, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : themeManager.perfolioTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? themeManager.perfolioTheme.tintColor : themeManager.perfolioTheme.primaryBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 8) {
        PerFolioPresetButton("₹500", isSelected: false) {}
        PerFolioPresetButton("₹1000", isSelected: true) {}
        PerFolioPresetButton("₹5000", isSelected: false) {}
        PerFolioPresetButton("Max", isSelected: false) {}
    }
    .padding()
    .background(Color(hex: "242424"))
    .environmentObject(ThemeManager())
}

