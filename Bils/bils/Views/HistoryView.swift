import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var splitStore: SplitRequestStore
    @State private var filter: SplitHistoryFilter = .unresolved

    var body: some View {
        VStack(spacing: 12) {
            Picker("Filter", selection: $filter) {
                ForEach(SplitHistoryFilter.allCases, id: \.self) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                if filteredRequests.isEmpty {
                    Text("No split requests yet.")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredRequests) { request in
                        NavigationLink(value: AppDestination.splitRequestDetail(id: request.id)) {
                            SplitRequestRow(request: request)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Split History")
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
                .frame(width: 40, height: 40)
                .overlay(
                    Text(request.initials)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(request.titleText)
                    .font(.subheadline.weight(.semibold))
                Text(request.merchant)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(request.amountText)
                    .font(.subheadline.weight(.semibold))
                Text(request.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
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
