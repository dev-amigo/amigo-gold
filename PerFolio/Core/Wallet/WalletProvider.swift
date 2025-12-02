import Foundation

/// Wallet provider/method for signing blockchain transactions
/// 
/// **Two Transaction Methods Available (for developer testing):**
/// 
/// 1. **Privy SDK** (`wallet.provider.request()`)
///    - Uses Privy iOS SDK's embedded wallet provider
///    - Gas sponsorship requires policies configured in Privy Dashboard
///    - May fail with "insufficient funds" if no policies match
/// 
/// 2. **Privy REST API** (`sponsor: true`)
///    - POST /v1/wallets/{wallet_id}/rpc with sponsor: true
///    - Same approach as web's useSendTransaction({ sponsor: true })
///    - Explicitly requests gas sponsorship in the API call
/// 
enum WalletProvider: String, CaseIterable, Identifiable {
    case privySDK = "privy_sdk"      // SDK method: wallet.provider.request()
    case privyRestAPI = "privy_api"  // REST API method: sponsor: true
    
    var id: String { rawValue }
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .privySDK:
            return "Privy SDK"
        case .privyRestAPI:
            return "Privy REST API"
        }
    }
    
    /// Short description of the provider
    var description: String {
        switch self {
        case .privySDK:
            return "Uses wallet.provider.request() - requires dashboard policies"
        case .privyRestAPI:
            return "Uses REST API with sponsor: true (same as web)"
        }
    }
    
    /// SF Symbol icon for UI
    var icon: String {
        switch self {
        case .privySDK:
            return "iphone"
        case .privyRestAPI:
            return "network"
        }
    }
    
    /// Whether this provider supports gas sponsorship
    var supportsGasSponsorship: Bool {
        switch self {
        case .privySDK:
            return true  // Via Privy dashboard policies
        case .privyRestAPI:
            return true  // Via sponsor: true flag
        }
    }
    
    /// Whether this provider is available in current build
    var isAvailable: Bool {
        switch self {
        case .privySDK:
            return true  // Always available
        case .privyRestAPI:
            return true  // Always available
        }
    }
    
    /// Badge text
    var badge: String? {
        switch self {
        case .privySDK:
            return "Requires Policies"
        case .privyRestAPI:
            return "Same as Web"
        }
    }
    
    /// Technical details for developers
    var technicalDetails: String {
        switch self {
        case .privySDK:
            return "wallet.provider.request(ethSendTransaction)"
        case .privyRestAPI:
            return "POST /v1/wallets/{id}/rpc { sponsor: true }"
        }
    }
    
    /// Get current selected provider from preferences
    static var current: WalletProvider {
        let rawValue = UserPreferences.selectedWalletProvider
        return WalletProvider(rawValue: rawValue) ?? .privyRestAPI  // Default to REST API
    }
    
    /// Save provider to preferences
    func select() {
        UserPreferences.selectedWalletProvider = self.rawValue
    }
}

