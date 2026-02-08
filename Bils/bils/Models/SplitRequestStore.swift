import Foundation

class SplitRequestStore: ObservableObject {
    static let shared = SplitRequestStore()

    @Published var requests: [SplitRequest] = []

    func add(_ request: SplitRequest) {
        DispatchQueue.main.async {
            self.requests.insert(request, at: 0)
        }
    }

    func updateStatus(id: UUID, status: SplitRequestStatus) {
        DispatchQueue.main.async {
            if let index = self.requests.firstIndex(where: { $0.id == id }) {
                self.requests[index].status = status
            }
        }
    }

    func request(for id: UUID) -> SplitRequest? {
        requests.first { $0.id == id }
    }
}
