import SwiftUI

enum AppDestination: Hashable {
    case home
    case splitEvenly(paymentID: UUID)
    case customSplit(paymentID: UUID)
    case history
}

class Router: ObservableObject {
    @Published var path = NavigationPath()
    @Published var pendingPaymentID: UUID?

    func navigate(to destination: AppDestination) {
        DispatchQueue.main.async {
            self.path.append(destination)
        }
    }

    func navigateToSplit(paymentID: UUID, even: Bool) {
        pendingPaymentID = paymentID
        if even {
            navigate(to: .splitEvenly(paymentID: paymentID))
        } else {
            navigate(to: .customSplit(paymentID: paymentID))
        }
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
