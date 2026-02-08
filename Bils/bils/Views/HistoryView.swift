import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var splitStore: SplitRequestStore
    @EnvironmentObject var notificationService: NotificationService
    @State private var filter: SplitHistoryFilter = .unresolved

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header

                filterPills

                VStack(spacing: 12) {
                    if filteredRequests.isEmpty {
                        Text("No split requests yet.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(filteredRequests) { request in
                            NavigationLink(value: AppDestination.splitRequestDetail(id: request.id)) {
                                SplitRequestRow(request: request)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 1.0))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredRequests: [SplitRequest] {
        splitStore.requests.filter { request in
            switch filter {
            case .unresolved:
                return request.status == .unresolved
            case .resolved:
                return request.status == .resolved
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Split history")
                .font(.title3.weight(.bold))

            Spacer()

            Button {
                notificationService.scheduleGenericNotification(
                    title: "Reminders sent",
                    body: "You reminded everyone about their split.",
                    delay: 1
                )
            } label: {
                Text("Remind All")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.96, green: 0.25, blue: 0.23))
            }
        }
    }

    private var filterPills: some View {
        HStack(spacing: 8) {
            ForEach(SplitHistoryFilter.allCases, id: \.self) { item in
                Button {
                    filter = item
                } label: {
                    Text(item.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(filter == item ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(filter == item ? Color(red: 0.96, green: 0.25, blue: 0.23) : Color(.systemGray6))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

enum SplitHistoryFilter: String, CaseIterable {
    case unresolved = "Unresolved"
    case resolved = "Resolved"
}

struct SplitRequestRow: View {
    let request: SplitRequest

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(request.initials)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if request.status == .unresolved {
                        Image(systemName: "bell.badge.fill")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.96, green: 0.25, blue: 0.23))
                    }
                    Text(request.titleText)
                        .font(.subheadline.weight(.semibold))
                }

                Text(request.merchant)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(request.amountText)
                        .font(.subheadline.weight(.semibold))
                    if request.status == .unresolved {
                        HistoryWavyUnderline()
                            .stroke(Color(red: 0.96, green: 0.25, blue: 0.23), lineWidth: 2)
                            .frame(width: 36, height: 6)
                    }
                }

                Text(request.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

struct HistoryWavyUnderline: Shape {
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

private extension SplitRequest {
    var initials: String {
        guard let first = participants.first?.nameSnapshot.first else { return "?" }
        return String(first).uppercased()
    }

    var titleText: String {
        switch direction {
        case .incoming:
            return "From \(participants.first?.nameSnapshot ?? "Friend")"
        case .outgoing:
            return "To \(participants.count) people"
        }
    }

    var amountText: String {
        let amount = participants.map { $0.amountOwed }.reduce(0, +)
        return String(format: "$%.2f", amount)
    }
}
