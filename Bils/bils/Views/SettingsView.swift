import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Demo Notifications")
                .font(.headline)

            Button {
                notificationService.scheduleDemoNotificationA()
            } label: {
                Text("Send Demo Notification 1")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                notificationService.scheduleDemoNotificationB()
            } label: {
                Text("Send Demo Notification 2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Divider()

            Text("Incoming Requests")
                .font(.headline)

            Button {
                notificationService.scheduleIncomingSplitRequestDemoA()
            } label: {
                Text("Simulate Incoming Request 1")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                notificationService.scheduleIncomingSplitRequestDemoB()
            } label: {
                Text("Simulate Incoming Request 2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
        .onAppear {
            notificationService.requestPermission()
        }
    }
}
