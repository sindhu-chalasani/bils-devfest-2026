import SwiftUI

struct CustomSplitView: View {
    let paymentID: UUID
    @EnvironmentObject var store: PaymentStore
    @Environment(\.dismiss) var dismiss

    @State private var splits: [SplitEntry] = [
        SplitEntry(name: "Me"),
        SplitEntry(name: ""),
    ]

    private var payment: Payment? {
        store.payment(for: paymentID)
    }

    private var totalAssigned: Double {
        splits.compactMap { Double($0.amount) }.reduce(0, +)
    }

    private var remaining: Double {
        (payment?.amount ?? 0) - totalAssigned
    }

    var body: some View {
        VStack(spacing: 20) {
            if let payment = payment {
                VStack(spacing: 8) {
                    Text(payment.merchant)
                        .font(.title2.weight(.bold))
                    Text(String(format: "$%.2f total", payment.amount))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Divider()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach($splits) { $entry in
                            HStack {
                                TextField("Name", text: $entry.name)
                                    .textFieldStyle(.roundedBorder)
                                TextField("$0.00", text: $entry.amount)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                            }
                        }

                        Button {
                            splits.append(SplitEntry(name: ""))
                        } label: {
                            Label("Add Person", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                    }
                }

                HStack {
                    Text("Remaining:")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "$%.2f", remaining))
                        .font(.headline)
                        .foregroundStyle(remaining == 0 ? .green : .orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    store.updateStatus(id: paymentID, status: .customSplit)
                    dismiss()
                } label: {
                    Text("Send Custom Split")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Text("Payment not found")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Custom Split")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SplitEntry: Identifiable {
    let id = UUID()
    var name: String
    var amount: String = ""
}
