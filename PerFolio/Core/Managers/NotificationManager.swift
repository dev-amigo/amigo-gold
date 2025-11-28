import Foundation
import Combine

/// Centralized notification management system
/// 
/// **IMPORTANT: When to Create Notifications**
/// Notifications should ONLY be created from REAL EVENTS, not from UI/dashboard loads:
/// 
/// ✅ DO create notifications from:
/// - Completed transactions (borrow, repay, swap, deposit, withdraw)
/// - Real price alerts (monitoring service detects significant price changes)
/// - Loan ratio threshold crossed (compare previous vs current)
/// - Push notifications from backend
/// - System updates or important announcements
/// 
/// ❌ DO NOT create notifications from:
/// - Dashboard/View loading or appearing
/// - Data refresh or reload
/// - Currency changes
/// - UI state updates
/// 
/// Example usage:
/// ```
/// // After successful borrow transaction
/// NotificationManager.shared.addTransactionNotification(
///     message: "Successfully borrowed 500 USDC",
///     actionButton: NotificationAction(title: "View Loan", destination: "loans", style: .primary)
/// )
/// ```
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let userDefaultsKey = "app_notifications"
    private let maxNotifications = 100 // Keep last 100 notifications
    
    private init() {
        loadNotifications()
        updateUnreadCount()
    }
    
    // MARK: - Public Methods
    
    /// Add a new notification
    /// NOTE: Only call this from real events (transactions, price alerts, etc.)
    /// NOT from dashboard/view loading
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        
        // Trim to max count
        if notifications.count > maxNotifications {
            notifications = Array(notifications.prefix(maxNotifications))
        }
        
        updateUnreadCount()
        saveNotifications()
        
        AppLogger.log("📬 New notification: \(notification.message)", category: "notifications")
    }
    
    /// Mark notification as read
    func markAsRead(_ id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            updateUnreadCount()
            saveNotifications()
        }
    }
    
    /// Mark all as read
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        saveNotifications()
    }
    
    /// Delete notification
    func deleteNotification(_ id: String) {
        notifications.removeAll { $0.id == id }
        updateUnreadCount()
        saveNotifications()
    }
    
    /// Clear all notifications
    func clearAll() {
        notifications.removeAll()
        updateUnreadCount()
        saveNotifications()
    }
    
    /// Get unread notifications
    func getUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    /// Get notifications by type
    func getNotifications(ofType type: NotificationType) -> [AppNotification] {
        return notifications.filter { $0.type == type }
    }
    
    // MARK: - Convenience Methods
    
    /// Add a safety alert
    func addSafetyAlert(message: String, priority: NotificationPriority = .high) {
        let notification = AppNotification(
            type: .safety,
            message: message,
            icon: "shield.fill",
            iconColor: priority == .urgent ? "red" : "orange",
            priority: priority
        )
        addNotification(notification)
    }
    
    /// Add a price change alert
    func addPriceChangeAlert(message: String, isPositive: Bool) {
        let notification = AppNotification(
            type: .priceChange,
            message: message,
            icon: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
            iconColor: isPositive ? "green" : "red"
        )
        addNotification(notification)
    }
    
    /// Add a transaction notification
    func addTransactionNotification(message: String, actionButton: NotificationAction? = nil) {
        let notification = AppNotification(
            type: .transaction,
            message: message,
            icon: "arrow.left.arrow.right",
            iconColor: "blue",
            actionButton: actionButton
        )
        addNotification(notification)
    }
    
    /// Add a system notification
    func addSystemNotification(title: String? = nil, message: String) {
        let notification = AppNotification(
            type: .system,
            title: title,
            message: message,
            icon: "gear"
        )
        addNotification(notification)
    }
    
    // MARK: - Private Methods
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    private func saveNotifications() {
        do {
            let data = try JSONEncoder().encode(notifications)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            AppLogger.log("❌ Failed to save notifications: \(error)", category: "notifications")
        }
    }
    
    private func loadNotifications() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        do {
            notifications = try JSONDecoder().decode([AppNotification].self, from: data)
            AppLogger.log("📬 Loaded \(notifications.count) notifications", category: "notifications")
        } catch {
            AppLogger.log("❌ Failed to load notifications: \(error)", category: "notifications")
        }
    }
}

