import Foundation
import UserNotifications
import Combine
import UIKit

/// Service for managing push notifications and permissions
@MainActor
final class NotificationService: ObservableObject {
    
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        Task {
            await checkPermissionStatus()
        }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permission from user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            
            await checkPermissionStatus()
            
            if granted {
                AppLogger.log("✅ Notification permission granted", category: "notifications")
                UserPreferences.notificationsEnabled = true
            } else {
                AppLogger.log("❌ Notification permission denied", category: "notifications")
                UserPreferences.notificationsEnabled = false
            }
            
            return granted
        } catch {
            AppLogger.log("❌ Error requesting notification permission: \(error.localizedDescription)", category: "notifications")
            return false
        }
    }
    
    /// Check current notification permission status
    func checkPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
        
        AppLogger.log("📊 Notification status: \(authorizationStatus.description)", category: "notifications")
    }
    
    /// Open app settings to allow user to enable notifications
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
            AppLogger.log("⚙️ Opening app settings", category: "notifications")
        }
    }
    
    // MARK: - Notification Scheduling (For Future Use)
    
    /// Schedule a local notification
    func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval = 5,
        repeats: Bool = false
    ) async throws {
        guard isAuthorized else {
            AppLogger.log("⚠️ Cannot schedule notification: Not authorized", category: "notifications")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try await notificationCenter.add(request)
        AppLogger.log("✅ Notification scheduled: \(title)", category: "notifications")
    }
    
    /// Schedule a test notification (for development)
    func scheduleTestNotification() async {
        do {
            try await scheduleNotification(
                title: "PerFolio Test",
                body: "Notifications are working! 🎉",
                identifier: "test-notification",
                timeInterval: 5
            )
            AppLogger.log("🧪 Test notification scheduled", category: "notifications")
        } catch {
            AppLogger.log("❌ Failed to schedule test notification: \(error.localizedDescription)", category: "notifications")
        }
    }
    
    /// Cancel a scheduled notification
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        AppLogger.log("🗑️ Notification cancelled: \(identifier)", category: "notifications")
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        AppLogger.log("🗑️ All notifications cancelled", category: "notifications")
    }
    
    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Notification Types (For Future Implementation)
    
    enum NotificationType {
        case priceAlert(token: String, price: Decimal)
        case loanHealthWarning(healthFactor: Decimal)
        case transactionConfirmed(txHash: String)
        case depositReceived(amount: Decimal, token: String)
        case withdrawalCompleted(amount: Decimal, currency: String)
        
        var identifier: String {
            switch self {
            case .priceAlert(let token, _):
                return "price-alert-\(token)"
            case .loanHealthWarning:
                return "loan-health-warning"
            case .transactionConfirmed(let txHash):
                return "transaction-\(txHash)"
            case .depositReceived:
                return "deposit-received"
            case .withdrawalCompleted:
                return "withdrawal-completed"
            }
        }
        
        var title: String {
            switch self {
            case .priceAlert(let token, _):
                return "\(token) Price Alert"
            case .loanHealthWarning:
                return "⚠️ Loan Health Warning"
            case .transactionConfirmed:
                return "✅ Transaction Confirmed"
            case .depositReceived:
                return "💰 Deposit Received"
            case .withdrawalCompleted:
                return "✅ Withdrawal Completed"
            }
        }
        
        var body: String {
            switch self {
            case .priceAlert(let token, let price):
                return "\(token) has reached \(price)"
            case .loanHealthWarning(let healthFactor):
                return "Your loan health factor is \(healthFactor). Consider adding collateral."
            case .transactionConfirmed(let txHash):
                return "Transaction confirmed: \(txHash.prefix(10))..."
            case .depositReceived(let amount, let token):
                return "\(amount) \(token) has been deposited to your wallet"
            case .withdrawalCompleted(let amount, let currency):
                return "\(amount) \(currency) withdrawal completed"
            }
        }
    }
}

// MARK: - UNAuthorizationStatus Extension

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
}

