import UserNotifications
import UIKit

// MARK: - Notification action/category identifiers

enum NotificationAction {
    static let dontSplit = "DONT_SPLIT_ACTION"
    static let customSplit = "CUSTOM_SPLIT_ACTION"
    static let category = "PAYMENT_SPLIT_CATEGORY"

    /// Prefix for preset actions — full identifier is "PRESET_0", "PRESET_1", etc.
    static let presetPrefix = "PRESET_"
}

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    @Published var isAuthorized = false

    // Posted when user taps a notification action
    // userInfo keys: "paymentID" (UUID), "action" (String), "presetIndex" (Int, optional)
    static let actionNotification = Notification.Name("NotificationService.action")

    override init() {
        super.init()
        registerCategories()
    }

    // MARK: - Request permission

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

    // MARK: - Register interactive category with preset contacts

    func registerCategories() {
        let presets = PresetStore.shared.presets

        // Build actions: preset contacts first, then Custom, then Don't Split
        // iOS allows max 4 actions in the long-press menu
        var actions: [UNNotificationAction] = []

        for (index, preset) in presets.prefix(2).enumerated() {
            let action = UNNotificationAction(
                identifier: "\(NotificationAction.presetPrefix)\(index)",
                title: "Split w/ \(preset.name)",
                options: []  // stays in background — "auto-sends"
            )
            actions.append(action)
        }

        let custom = UNNotificationAction(
            identifier: NotificationAction.customSplit,
            title: "Custom...",
            options: [.foreground]  // opens the app
        )
        actions.append(custom)

        let dontSplit = UNNotificationAction(
            identifier: NotificationAction.dontSplit,
            title: "Don't Split",
            options: [.destructive]
        )
        actions.append(dontSplit)

        let paymentCategory = UNNotificationCategory(
            identifier: NotificationAction.category,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([paymentCategory])
    }

    // MARK: - Schedule a payment notification

    func schedulePaymentNotification(payment: Payment, delay: TimeInterval = 8) {
        // Re-register so presets are up to date
        registerCategories()

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

    // MARK: - Test notification

    func sendTestNotification() {
        registerCategories()

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

// MARK: - Handle notification actions

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let paymentIDString = userInfo["paymentID"] as? String
        let paymentID = paymentIDString.flatMap { UUID(uuidString: $0) }
        let actionID = response.actionIdentifier

        // Preset action — e.g. "PRESET_0", "PRESET_1"
        if actionID.hasPrefix(NotificationAction.presetPrefix),
           let indexString = actionID.split(separator: "_").last,
           let index = Int(indexString) {
            if let id = paymentID {
                PaymentStore.shared.updateStatus(id: id, status: .splitEvenly)
            }
            NotificationCenter.default.post(
                name: NotificationService.actionNotification,
                object: nil,
                userInfo: [
                    "paymentID": paymentID as Any,
                    "action": "preset",
                    "presetIndex": index
                ]
            )
            completionHandler()
            return
        }

        switch actionID {
        case NotificationAction.customSplit:
            NotificationCenter.default.post(
                name: NotificationService.actionNotification,
                object: nil,
                userInfo: ["paymentID": paymentID as Any, "action": "customSplit"]
            )

        case NotificationAction.dontSplit:
            if let id = paymentID {
                PaymentStore.shared.updateStatus(id: id, status: .ignored)
            }

        case UNNotificationDefaultActionIdentifier:
            // Tapped notification body → open app to custom split
            NotificationCenter.default.post(
                name: NotificationService.actionNotification,
                object: nil,
                userInfo: ["paymentID": paymentID as Any, "action": "customSplit"]
            )

        default:
            break
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
