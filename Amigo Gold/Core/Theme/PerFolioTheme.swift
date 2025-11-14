import SwiftUI

/// PerFolio Gold Theme Tokens
struct PerFolioTheme {
    let primaryBackground: Color
    let secondaryBackground: Color
    let tintColor: Color
    let buttonBackground: Color
    let goldenBoxGradient: LinearGradient
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let border: Color
    let success: Color
    let warning: Color
    let danger: Color
    
    static let gold = PerFolioTheme(
        primaryBackground: Color(hex: "1D1D1D"),
        secondaryBackground: Color(hex: "242424"),
        tintColor: Color(hex: "D0B070"),
        buttonBackground: Color(hex: "9D7618"),
        goldenBoxGradient: LinearGradient(
            colors: [Color(hex: "D0B070"), Color(hex: "B88A3C")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        textPrimary: .white,
        textSecondary: Color.white.opacity(0.8),
        textTertiary: Color.white.opacity(0.6),
        border: Color.white.opacity(0.1),
        success: Color(hex: "4ADE80"),
        warning: Color(hex: "FBBF24"),
        danger: Color(hex: "EF4444")
    )
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

