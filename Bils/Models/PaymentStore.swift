import Foundation

class PaymentStore: ObservableObject {
    @Published var payments: [Payment] = []

    static let shared = PaymentStore()

    func add(_ payment: Payment) {
        DispatchQueue.main.async {
            self.payments.insert(payment, at: 0)
        }
    }

    func updateStatus(id: UUID, status: SplitStatus) {
        DispatchQueue.main.async {
            if let index = self.payments.firstIndex(where: { $0.id == id }) {
                self.payments[index].splitStatus = status
            }
        }
    }

    func payment(for id: UUID) -> Payment? {
        payments.first { $0.id == id }
    }
}
