import SwiftUI

struct SplitRequestDetailView: View {
    let requestID: UUID
    @EnvironmentObject var splitStore: SplitRequestStore
    @EnvironmentObject var notificationService: NotificationService

    private var request: SplitRequest? {
        splitStore.request(for: requestID)
    }

    var body: some View {
        Group {
            if let request = request {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(request.merchant)
                                .font(.title2.weight(.bold))
                            Text(request.direction == .incoming ? "You owe" : "They owe")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(amountText(for: request))
                            .font(.system(size: 36, weight: .bold))

                        if !request.note.isEmpty {
                            Text("Note: \(request.note)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Participants")
                                .font(.headline)

                            ForEach(request.participants) { participant in
                                HStack {
                                    Text(participant.nameSnapshot)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(String(format: "$%.2f", participant.amountOwed))
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Divider()

                        HStack(spacing: 12) {
                            Button {
                                sendReminder(for: request)
                            } label: {
                                Text("Send Reminder")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                splitStore.updateStatus(id: request.id, status: .resolved)
                            } label: {
                                Text("Mark Resolved")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Request not found")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Split Request")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendReminder(for request: SplitRequest) {
        let title = "Reminder sent"
        let body = "You reminded \(request.participants.first?.nameSnapshot ?? "a friend")."
        notificationService.scheduleGenericNotification(title: title, body: body, delay: 1)
    }

    private func amountText(for request: SplitRequest) -> String {
        let amount = request.participants.map { $0.amountOwed }.reduce(0, +)
        return String(format: "$%.2f", amount)
    }
}
