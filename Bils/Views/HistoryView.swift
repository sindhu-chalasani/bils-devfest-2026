import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: PaymentStore

    var body: some View {
        List {
            if store.payments.isEmpty {
                Text("No payments yet. Tap \"I Paid\" to get started!")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(store.payments) { payment in
                    PaymentRow(payment: payment)
                }
            }
        }
        .navigationTitle("Payment History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
