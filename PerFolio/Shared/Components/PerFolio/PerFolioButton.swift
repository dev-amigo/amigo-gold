import SwiftUI

/// Reusable button component with PerFolio styling
struct PerFolioButton: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let title: String
    private let style: ButtonStyle
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void
    
    enum ButtonStyle {
        case primary        // Gold button background
        case secondary      // Outlined with gold border
        case ghost          // Text only
        case disabled       // Grayed out
    }
    
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: { 
            if !isDisabled && !isLoading { 
                HapticManager.shared.medium()
                action() 
            } 
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(foregroundColor)
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .overlay(overlayView)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return themeManager.perfolioTheme.tintColor
        case .ghost:
            return themeManager.perfolioTheme.textPrimary
        case .disabled:
            return themeManager.perfolioTheme.textTertiary
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return themeManager.perfolioTheme.buttonBackground
        case .secondary:
            return themeManager.perfolioTheme.secondaryBackground
        case .ghost:
            return .clear
        case .disabled:
            return themeManager.perfolioTheme.primaryBackground
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(themeManager.perfolioTheme.tintColor, lineWidth: 1.5)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PerFolioButton("Primary Button", style: .primary) {}
        PerFolioButton("Secondary Button", style: .secondary) {}
        PerFolioButton("Loading...", style: .primary, isLoading: true) {}
        PerFolioButton("Disabled Button", style: .disabled, isDisabled: true) {}
    }
    .padding()
    .background(Color(hex: "1D1D1D"))
    .environmentObject(ThemeManager())
}

