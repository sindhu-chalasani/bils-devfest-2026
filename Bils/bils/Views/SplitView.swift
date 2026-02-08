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
                    VStack(spacing: 24) {
                        // Payment header
                        VStack(spacing: 4) {
                            Text(payment.merchant)
                                .font(.title2.weight(.bold))
                            Text(String(format: "$%.2f", payment.amount))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 12)

                        // People picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Split with")
                                .font(.headline)

                            if presetStore.presets.isEmpty {
                                Text("No contacts yet. Add people in Settings.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(presetStore.presets) { person in
                                    personRow(person)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)

                        // Split mode picker
                        if !selectedPeople.isEmpty {
                            VStack(spacing: 16) {
                                Picker("Split Mode", selection: $splitMode) {
                                    ForEach(SplitMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if splitMode == .even {
                                    evenSplitSection
                                } else {
                                    customSplitSection
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Note")
                                        .font(.subheadline.weight(.medium))
                                    TextField("Add note", text: $note)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                        }
                    }
                    .padding()
                }

                // Send button pinned to bottom
                if !selectedPeople.isEmpty {
                    Button {
                        sendSplit()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Notification")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            } else {
                Spacer()
                Text("Payment not found")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Split Bill")
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
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray4))
                        .frame(width: 40, height: 40)
                    Text(String(person.name.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(person.phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : Color(.systemGray3))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Even split breakdown

    private var evenSplitSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("They each owe")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "$%.2f", othersShare))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.blue)
            }

            Divider()

            VStack(spacing: 6) {
                HStack {
                    Text("You")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "$%.2f", yourShare))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(selectedPresets) { person in
                    HStack {
                        Text(person.name)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "$%.2f", othersShare))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Custom amounts

    private var customSplitSection: some View {
        VStack(spacing: 12) {
            ForEach(selectedPresets) { person in
                HStack {
                    Text(person.name)
                        .font(.body.weight(.medium))
                    Spacer()
                    HStack(spacing: 4) {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: binding(for: person.id))
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Divider()

            HStack {
                Text("Remaining")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "$%.2f", remaining))
                    .font(.headline)
                    .foregroundStyle(
                        abs(remaining) < 0.01 ? .green : .orange
                    )
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
}
