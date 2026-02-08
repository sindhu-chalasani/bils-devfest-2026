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
                            Text(primaryName(for: request))
                                .font(.title3.weight(.bold))

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(amountText(for: request))
                                    .font(.system(size: 34, weight: .bold))

                                Text("/ \(String(format: "$%.2f", request.totalAmount)) owed")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            WavyUnderline()
                                .stroke(Color(red: 0.96, green: 0.25, blue: 0.23), lineWidth: 3)
                                .frame(width: 90, height: 8)

                            Text(request.merchant)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !request.note.isEmpty {
                            Text("Note: \(request.note)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Unresolved payments")
                                .font(.headline)

                            HStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(request.merchant)
                                        .font(.subheadline.weight(.semibold))
                                    Text(request.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(amountText(for: request))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                        }

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
                            .tint(Color(red: 0.96, green: 0.25, blue: 0.23))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            } else {
                Text("Request not found")
                    .foregroundStyle(.secondary)
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 1.0))
        .navigationTitle("")
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

    private func primaryName(for request: SplitRequest) -> String {
        request.participants.first?.nameSnapshot ?? "Split"
    }
}

struct WavyUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let amplitude: CGFloat = rect.height / 2.5
        let midY = rect.midY
        let width = rect.width
        let step = width / 6

        path.move(to: CGPoint(x: 0, y: midY))
        for i in 0...6 {
            let x = CGFloat(i) * step
            let y = i.isMultiple(of: 2) ? midY - amplitude : midY + amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}
