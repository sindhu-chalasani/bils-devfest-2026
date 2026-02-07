import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: Router
    @StateObject private var store = PaymentStore.shared
    @StateObject private var notificationService = NotificationService.shared

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .environmentObject(store)
                .environmentObject(notificationService)
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .home:
                        HomeView()
                            .environmentObject(store)
                    case .splitEvenly(let paymentID):
                        SplitEvenlyView(paymentID: paymentID)
                            .environmentObject(store)
                    case .customSplit(let paymentID):
                        CustomSplitView(paymentID: paymentID)
                            .environmentObject(store)
                    case .history:
                        HistoryView()
                            .environmentObject(store)
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationService.actionNotification)) { notification in
            guard let action = notification.userInfo?["action"] as? String,
                  let paymentID = notification.userInfo?["paymentID"] as? UUID else { return }

            router.popToRoot()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                switch action {
                case "splitEvenly":
                    router.navigate(to: .splitEvenly(paymentID: paymentID))
                case "customSplit":
                    router.navigate(to: .customSplit(paymentID: paymentID))
                default:
                    break
                }
            }
        }
    }
}
