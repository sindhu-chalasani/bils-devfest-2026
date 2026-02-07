import UserNotifications
import UIKit

// MARK: - Notification action/category identifiers

enum NotificationAction {
    static let splitEvenly = "SPLIT_EVENLY_ACTION"
    static let customSplit = "CUSTOM_SPLIT_ACTION"
    static let ignore = "IGNORE_ACTION"
    static let category = "PAYMENT_SPLIT_CATEGORY"
}

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    @Published var isAuthorized = false

    // Posted when user taps a notification action
    // userInfo: ["paymentID": UUID, "action": String]
    static let actionNotification = Notification.Name("NotificationService.action")

    override init() {
        super.init()
        registerCategories()
    }

    // MARK: - Phase 1: Request permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Phase 2: Register interactive category

    private func registerCategories() {
        let splitEvenly = UNNotificationAction(
            identifier: NotificationAction.splitEvenly,
            title: "Split Evenly",
            options: [.foreground]
        )
        let customSplit = UNNotificationAction(
            identifier: NotificationAction.customSplit,
            title: "Custom Split",
            options: [.foreground]
        )
        let ignore = UNNotificationAction(
            identifier: NotificationAction.ignore,
            title: "Ignore",
            options: [.destructive]
        )

        let paymentCategory = UNNotificationCategory(
            identifier: NotificationAction.category,
            actions: [splitEvenly, customSplit, ignore],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([paymentCategory])
    }

    // MARK: - Phase 4: Schedule a payment notification

    /// Schedules a local notification after a delay, simulating the
    /// "you just paid, want to split?" flow.
    func schedulePaymentNotification(payment: Payment, delay: TimeInterval = 8) {
        let content = UNMutableNotificationContent()
        content.title = "Split this bill?"
        content.body = String(
            format: "You paid $%.2f at %@. Want to split it?",
            payment.amount,
            payment.merchant
        )
        content.sound = .default
        content.categoryIdentifier = NotificationAction.category
        content.userInfo = ["paymentID": payment.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: payment.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Phase 1: Simple test notification

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Bils is working!"
        content.body = "Notifications are set up correctly."
        content.sound = .default
        content.categoryIdentifier = NotificationAction.category

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Phase 3: Handle notification actions

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Called when user taps on notification or an action button
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let paymentIDString = userInfo["paymentID"] as? String
        let paymentID = paymentIDString.flatMap { UUID(uuidString: $0) }

        switch response.actionIdentifier {
        case NotificationAction.splitEvenly:
            if let id = paymentID {
                PaymentStore.shared.updateStatus(id: id, status: .splitEvenly)
            }
            NotificationCenter.default.post(
                name: NotificationService.actionNotification,
                object: nil,
                userInfo: ["paymentID": paymentID as Any, "action": "splitEvenly"]
            )

        case NotificationAction.customSplit:
            NotificationCenter.default.post(
                name: NotificationService.actionNotification,
                object: nil,
                userInfo: ["paymentID": paymentID as Any, "action": "customSplit"]
            )

        case NotificationAction.ignore:
            if let id = paymentID {
                PaymentStore.shared.updateStatus(id: id, status: .ignored)
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body (not an action button)
            NotificationCenter.default.post(
                name: NotificationService.actionNotification,
                object: nil,
                userInfo: ["paymentID": paymentID as Any, "action": "splitEvenly"]
            )

        default:
            break
        }

        completionHandler()
    }

    /// Show notifications even when app is in foreground (useful for demo)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
