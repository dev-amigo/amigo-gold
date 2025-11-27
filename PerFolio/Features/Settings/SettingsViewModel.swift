import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isHapticEnabled: Bool {
        didSet {
            HapticManager.shared.isHapticEnabled = isHapticEnabled
        }
    }
    
    @Published var isSoundEnabled: Bool {
        didSet {
            HapticManager.shared.isSoundEnabled = isSoundEnabled
        }
    }
    
    @Published var showingSafari = false
    @Published var safariURL: URL?
    @Published var showingLogoutConfirmation = false
    @Published var addressCopied = false
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserPreferences.notificationsEnabled = notificationsEnabled
        }
    }
    
    // MARK: - Currency Preferences
    
    var currentCurrency: String {
        UserPreferences.defaultCurrency
    }
    
    var currencySymbol: String {
        UserPreferences.currencySymbol
    }
    
    // MARK: - User Info
    
    var userEmail: String {
        PrivyAuthCoordinator.shared.getUserEmail() ?? "user@perfolio.ai"
    }
    
    var walletAddress: String? {
        UserDefaults.standard.string(forKey: "userWalletAddress")
    }
    
    // MARK: - App Info
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Libraries
    
    struct Library: Identifiable {
        let id = UUID()
        let name: String
        let version: String
        let licenseURL: URL?
    }
    
    let libraries: [Library] = [
        Library(
            name: "Privy SDK",
            version: "1.0.0",
            licenseURL: URL(string: "https://github.com/privy-io/privy-ios")
        ),
        Library(
            name: "Swift",
            version: "6.0",
            licenseURL: URL(string: "https://swift.org/LICENSE.txt")
        ),
        Library(
            name: "SwiftUI",
            version: "iOS 18.6",
            licenseURL: URL(string: "https://developer.apple.com/documentation/swiftui")
        )
    ]
    
    // MARK: - Initialization
    
    init() {
        self.isHapticEnabled = HapticManager.shared.isHapticEnabled
        self.isSoundEnabled = HapticManager.shared.isSoundEnabled
        self.notificationsEnabled = UserPreferences.notificationsEnabled
    }
    
    // MARK: - Actions
    
    func truncatedAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let start = address.prefix(6)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }
    
    func copyAddress(_ address: String) {
        UIPasteboard.general.string = address
        addressCopied = true
        
        // Reset after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            addressCopied = false
        }
    }
    
    func openEmail() {
        if let url = URL(string: "mailto:support@perfolio.ai?subject=PerFolio Support Request") {
            UIApplication.shared.open(url)
        }
    }
    
    func openTermsOfService() {
        safariURL = URL(string: "https://perfolio.ai/terms")
        showingSafari = true
    }
    
    func openPrivacyPolicy() {
        safariURL = URL(string: "https://perfolio.ai/privacy")
        showingSafari = true
    }
    
    func openLibraryLicense(_ library: Library) {
        safariURL = library.licenseURL
        showingSafari = true
    }
    
    func updateNotificationPreference(_ enabled: Bool) {
        UserPreferences.notificationsEnabled = enabled
        AppLogger.log("✅ Notifications preference updated: \(enabled)", category: "settings")
        
        // Optionally check actual system permission status
        Task {
            await NotificationService.shared.checkPermissionStatus()
        }
    }
    
    func showLogoutConfirmation() {
        showingLogoutConfirmation = true
    }
    
    func logout() {
        // Clear all user data from UserDefaults
        UserDefaults.standard.removeObject(forKey: "userWalletAddress")
        UserDefaults.standard.removeObject(forKey: "userWalletId")
        UserDefaults.standard.removeObject(forKey: "privyUserId")
        UserDefaults.standard.removeObject(forKey: "privyAccessToken")
        UserDefaults.standard.removeObject(forKey: "privyUserEmail")
        
        AppLogger.log("User data cleared from UserDefaults", category: "auth")
        
        // Logout from Privy
        Task {
            await PrivyAuthCoordinator.shared.logout()
            
            // Navigate to login (handled by AppRootView)
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
        }
    }
}

