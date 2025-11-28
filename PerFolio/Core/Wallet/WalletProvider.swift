import Foundation

/// Wallet providers for signing blockchain transactions
/// 
/// Supports multiple wallet implementations to enable different features:
/// - Privy: Default embedded wallet (standard transactions)
/// - Alchemy AA: Account Abstraction with gas sponsorship (dev mode only)
enum WalletProvider: String, CaseIterable, Identifiable {
    case privyEmbedded = "privy"
    case alchemyAA = "alchemy"
    
    var id: String { rawValue }
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .privyEmbedded:
            return "Privy Embedded Wallet"
        case .alchemyAA:
            return "Alchemy Account Abstraction"
        }
    }
    
    /// Short description of the provider
    var description: String {
        switch self {
        case .privyEmbedded:
            return "Default wallet powered by Privy SDK"
        case .alchemyAA:
            return "Gas-sponsored transactions via Alchemy"
        }
    }
    
    /// SF Symbol icon for UI
    var icon: String {
        switch self {
        case .privyEmbedded:
            return "lock.shield.fill"
        case .alchemyAA:
            return "sparkles"
        }
    }
    
    /// Whether this provider supports gas sponsorship
    var supportsGasSponsorship: Bool {
        switch self {
        case .privyEmbedded:
            return false
        case .alchemyAA:
            return true
        }
    }
    
    /// Whether this provider is available in current build
    var isAvailable: Bool {
        switch self {
        case .privyEmbedded:
            return true  // Always available
        case .alchemyAA:
            #if DEBUG
            return true  // Only available in debug builds
            #else
            return false
            #endif
        }
    }
    
    /// Badge text (e.g., "Sponsored", "Default")
    var badge: String? {
        switch self {
        case .privyEmbedded:
            return "Default"
        case .alchemyAA:
            return "Gas Sponsored"
        }
    }
    
    /// Get current selected provider from preferences
    static var current: WalletProvider {
        let rawValue = UserPreferences.selectedWalletProvider
        return WalletProvider(rawValue: rawValue) ?? .privyEmbedded
    }
    
    /// Save provider to preferences
    func select() {
        UserPreferences.selectedWalletProvider = self.rawValue
    }
}

