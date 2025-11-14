import SwiftUI

/// Reusable input field with label and optional preset buttons
struct PerFolioInputField: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding private var text: String
    
    private let label: String
    private let placeholder: String
    private let leadingIcon: String?
    private let trailingText: String?
    private let presetValues: [String]
    private let keyboardType: UIKeyboardType
    
    init(
        label: String,
        placeholder: String = "0.00",
        text: Binding<String>,
        leadingIcon: String? = nil,
        trailingText: String? = nil,
        presetValues: [String] = [],
        keyboardType: UIKeyboardType = .decimalPad
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.leadingIcon = leadingIcon
        self.trailingText = trailingText
        self.presetValues = presetValues
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            
            PerFolioTextField(
                placeholder: placeholder,
                text: $text,
                leadingIcon: leadingIcon,
                trailingText: trailingText,
                keyboardType: keyboardType
            )
            
            if !presetValues.isEmpty {
                HStack(spacing: 8) {
                    ForEach(presetValues, id: \.self) { value in
                        PerFolioPresetButton(value) {
                            text = value.replacingOccurrences(of: "₹", with: "")
                                       .replacingOccurrences(of: "%", with: "")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PerFolioInputField(
            label: "Amount",
            text: .constant(""),
            leadingIcon: "indianrupeesign",
            presetValues: ["₹500", "₹1000", "₹5000"]
        )
        
        PerFolioInputField(
            label: "PAXG Collateral",
            text: .constant(""),
            trailingText: "PAXG",
            presetValues: ["25%", "50%", "75%", "100%"]
        )
    }
    .padding()
    .background(Color(hex: "242424"))
    .environmentObject(ThemeManager())
}

