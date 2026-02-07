import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: Router
    @StateObject private var store = PaymentStore.shared
    @StateObject private var presetStore = PresetStore.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .environmentObject(store)
                .environmentObject(presetStore)
                .environmentObject(notificationService)
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .home:
                        HomeView()
                            .environmentObject(store)
                            .environmentObject(presetStore)
                    case .split(let paymentID):
                        SplitView(paymentID: paymentID)
                            .environmentObject(store)
                    case .history:
                        HistoryView()
                            .environmentObject(store)
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationService.actionNotification)) { notification in
            guard let action = notification.userInfo?["action"] as? String else { return }
            let paymentID = notification.userInfo?["paymentID"] as? UUID

            switch action {
            case "preset":
                if let index = notification.userInfo?["presetIndex"] as? Int,
                   index < presetStore.presets.count {
                    let preset = presetStore.presets[index]
                    showToast("Split request sent to \(preset.name)!")
                }

            case "customSplit":
                guard let paymentID = paymentID else { return }
                router.popToRoot()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.navigate(to: .split(paymentID: paymentID))
                }

            default:
                break
            }
        }
        .overlay {
            if let message = toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}
