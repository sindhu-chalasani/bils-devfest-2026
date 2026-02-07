import SwiftUI

struct SplitEvenlyView: View {
    let paymentID: UUID
    @EnvironmentObject var store: PaymentStore
    @Environment(\.dismiss) var dismiss

    @State private var numberOfPeople = 2

    private var payment: Payment? {
        store.payment(for: paymentID)
    }

    private var perPerson: Double {
        guard let payment = payment, numberOfPeople > 0 else { return 0 }
        return payment.amount / Double(numberOfPeople)
    }

    var body: some View {
        VStack(spacing: 24) {
            if let payment = payment {
                VStack(spacing: 8) {
                    Text(payment.merchant)
                        .font(.title2.weight(.bold))
                    Text(String(format: "$%.2f total", payment.amount))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(spacing: 12) {
                    Text("Split between")
                        .font(.headline)

                    HStack(spacing: 20) {
                        Button {
                            if numberOfPeople > 2 { numberOfPeople -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                        }

                        Text("\(numberOfPeople) people")
                            .font(.title2.weight(.medium))
                            .frame(minWidth: 100)

                        Button {
                            numberOfPeople += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                }

                VStack(spacing: 4) {
                    Text(String(format: "$%.2f", perPerson))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("per person")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)

                Button {
                    store.updateStatus(id: paymentID, status: .splitEvenly)
                    dismiss()
                } label: {
                    Text("Send Split Request")
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
        .navigationTitle("Split Evenly")
        .navigationBarTitleDisplayMode(.inline)
    }
}
