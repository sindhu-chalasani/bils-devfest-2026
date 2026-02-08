import SwiftUI

enum SplitMode: String, CaseIterable {
    case even = "Split Evenly"
    case custom = "Custom Amounts"
}

struct SplitView: View {
    let paymentID: UUID
    @EnvironmentObject var store: PaymentStore
    @EnvironmentObject var splitStore: SplitRequestStore
    @Environment(\.dismiss) var dismiss

    @StateObject private var presetStore = PresetStore.shared
    @State private var selectedPeople: Set<UUID> = []
    @State private var splitMode: SplitMode = .even
    @State private var customAmounts: [UUID: String] = [:]
    @State private var showSentConfirmation = false
    @State private var note = ""
    @State private var searchText = ""
    @State private var didSplitEven = false

    private var payment: Payment? {
        store.payment(for: paymentID)
    }

    private var selectedPresets: [Preset] {
        presetStore.presets.filter { selectedPeople.contains($0.id) }
    }

    // +1 for "you"
    private var totalSplitters: Int {
        selectedPeople.count + 1
    }

    /// Your share rounds down — the others absorb the extra cents.
    private var yourShare: Double {
        guard let payment = payment, totalSplitters > 0 else { return 0 }
        return (payment.amount / Double(totalSplitters) * 100).rounded(.down) / 100
    }

    private var othersShare: Double {
        guard let payment = payment, selectedPeople.count > 0 else { return 0 }
        let leftover = payment.amount - yourShare
        return (leftover / Double(selectedPeople.count) * 100).rounded(.up) / 100
    }

    private var customTotal: Double {
        customAmounts.values.compactMap { Double($0) }.reduce(0, +)
    }

    private var remaining: Double {
        (payment?.amount ?? 0) - customTotal
    }

    var body: some View {
        VStack(spacing: 0) {
            if let payment = payment {
                ScrollView {
                    VStack(spacing: 18) {
                        header(payment)

                        searchBar

                        addFriendRow

                        topPeopleHeader

                        VStack(spacing: 0) {
                            if presetStore.presets.isEmpty {
                                Text("No contacts yet. Add people in Settings.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(filteredPresets) { person in
                                    personRow(person)
                                        .padding(.vertical, 8)

                                    if person.id != filteredPresets.last?.id {
                                        Divider()
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)

                        if !selectedPeople.isEmpty {
                            amountSection(payment)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            } else {
                Spacer()
                Text("Payment not found")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 1.0))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showSentConfirmation {
                sentOverlay
            }
        }
    }

    // MARK: - Person row with checkmark

    private func personRow(_ person: Preset) -> some View {
        let isSelected = selectedPeople.contains(person.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedPeople.remove(person.id)
                    customAmounts.removeValue(forKey: person.id)
                } else {
                    selectedPeople.insert(person.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(person.name.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(person.phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .stroke(isSelected ? Color(red: 0.96, green: 0.25, blue: 0.23) : Color(.systemGray4), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color(red: 0.96, green: 0.25, blue: 0.23) : .clear)
                            .frame(width: 10, height: 10)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Even split breakdown

    private var evenSplitSection: some View {
        VStack(spacing: 10) {
            ForEach(selectedPresets) { person in
                HStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(person.name.prefix(1)).uppercased())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.name)
                            .font(.subheadline.weight(.semibold))
                        Text("Split")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(String(format: "$%.2f", didSplitEven ? othersShare : 0))
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    // MARK: - Custom amounts

    private var customSplitSection: some View {
        VStack(spacing: 10) {
            ForEach(selectedPresets) { person in
                HStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(person.name.prefix(1)).uppercased())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.name)
                            .font(.subheadline.weight(.semibold))
                        Text("Custom")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: binding(for: person.id))
                            .keyboardType(.decimalPad)
                            .frame(width: 72)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            HStack {
                Text("Left to pay")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "$%.2f", remaining))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(abs(remaining) < 0.01 ? .green : .orange)
            }
        }
    }

    private func binding(for personID: UUID) -> Binding<String> {
        Binding(
            get: { customAmounts[personID] ?? "" },
            set: { customAmounts[personID] = $0 }
        )
    }

    // MARK: - Send

    private func sendSplit() {
        guard let payment = payment else { return }

        let status: SplitStatus = splitMode == .even ? .splitEvenly : .customSplit
        store.updateStatus(id: paymentID, status: status)

        let participants: [SplitParticipant] = selectedPresets.compactMap { person in
            let amount: Double
            if splitMode == .even {
                amount = othersShare
            } else {
                amount = Double(customAmounts[person.id] ?? "") ?? 0
            }

            guard amount > 0 else { return nil }
            return SplitParticipant(
                presetID: person.id,
                nameSnapshot: person.name,
                amountOwed: amount
            )
        }

        if !participants.isEmpty {
            let request = SplitRequest(
                paymentID: payment.id,
                merchant: payment.merchant,
                totalAmount: payment.amount,
                direction: .outgoing,
                note: note,
                participants: participants
            )
            splitStore.add(request)
        }

        withAnimation { showSentConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }

    private var sentOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "paperplane.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Request Sent!")
                .font(.headline)
            Text(selectedPresets.map(\.name).joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search friends", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private var addFriendRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundStyle(.primary)
            Text("Add a friend")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private var topPeopleHeader: some View {
        HStack {
            Text("Top people / groups")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private func header(_ payment: Payment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Split a transaction")
                .font(.title3.weight(.bold))

            HStack {
                Text(payment.merchant)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(timeString(for: payment.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func amountSection(_ payment: Payment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "$%.2f", payment.amount))
                    .font(.system(size: 36, weight: .bold))
                Text(splitMode == .custom ? "left to pay" : "total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if splitMode == .even {
                evenSplitSection
            } else {
                customSplitSection
            }

            HStack {
                Button {
                    splitMode = .even
                    didSplitEven = true
                } label: {
                    Text("Split even")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.96, green: 0.25, blue: 0.23))

                Button {
                    sendSplit()
                } label: {
                    Text("Send")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.96, green: 0.25, blue: 0.23))
            }

            Button {
                splitMode = .custom
                didSplitEven = false
            } label: {
                Text("Custom amounts")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)

            TextField("Add note", text: $note)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    private var filteredPresets: [Preset] {
        guard !searchText.isEmpty else { return presetStore.presets }
        return presetStore.presets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.phone.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
