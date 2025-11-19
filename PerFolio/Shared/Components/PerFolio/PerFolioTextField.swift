import SwiftUI

/// Reusable text field component with PerFolio styling
struct PerFolioTextField: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding private var text: String
    
    private let placeholder: String
    private let leadingIcon: String?
    private let trailingText: String?
    private let keyboardType: UIKeyboardType
    
    init(
        placeholder: String,
        text: Binding<String>,
        leadingIcon: String? = nil,
        trailingText: String? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.leadingIcon = leadingIcon
        self.trailingText = trailingText
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                .keyboardType(keyboardType)
            
            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
            }
        }
        .padding(12)
        .background(themeManager.perfolioTheme.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 16) {
        PerFolioTextField(
            placeholder: "0.00",
            text: .constant(""),
            trailingText: "USDC",
            keyboardType: .decimalPad
        )
        
        PerFolioTextField(
            placeholder: "Enter amount",
            text: .constant(""),
            leadingIcon: "indianrupeesign"
        )
    }
    .padding()
    .background(Color(hex: "242424"))
    .environmentObject(ThemeManager())
}
