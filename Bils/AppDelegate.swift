import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set the notification service as the delegate so it receives action callbacks
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        return true
    }
}
