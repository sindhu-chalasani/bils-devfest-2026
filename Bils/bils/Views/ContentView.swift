import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var router: Router
    @StateObject private var store = PaymentStore.shared
    @StateObject private var presetStore = PresetStore.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var splitStore = SplitRequestStore.shared
    @State private var toastMessage: String?

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0)

        let selectedColor = UIColor(red: 0.96, green: 0.25, blue: 0.23, alpha: 1.0)
        let normalColor = UIColor.gray
        let font = UIFont.systemFont(ofSize: 11, weight: .semibold)

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: font
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: font
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .environmentObject(store)
            .environmentObject(presetStore)
            .environmentObject(notificationService)
            .environmentObject(splitStore)
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .home:
                    HomeView()
                        .environmentObject(store)
                        .environmentObject(presetStore)
                case .split(let paymentID):
                    SplitView(paymentID: paymentID)
                        .environmentObject(store)
                        .environmentObject(splitStore)
                case .history:
                    HistoryView()
                        .environmentObject(store)
                        .environmentObject(splitStore)
                        .environmentObject(notificationService)
                case .splitRequestDetail(let id):
                    SplitRequestDetailView(requestID: id)
                        .environmentObject(splitStore)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationService.actionNotification)) { notification in
            guard let action = notification.userInfo?["action"] as? String else { return }
            let paymentID = notification.userInfo?["paymentID"] as? UUID
            let splitRequestID = notification.userInfo?["splitRequestID"] as? UUID

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

            case "incomingRequest":
                guard let splitRequestID = splitRequestID else { return }
                router.popToRoot()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.navigate(to: .splitRequestDetail(id: splitRequestID))
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
