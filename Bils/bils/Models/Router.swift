import SwiftUI

enum AppDestination: Hashable {
    case home
    case split(paymentID: UUID)
    case history
    case splitRequestDetail(id: UUID)
}

class Router: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to destination: AppDestination) {
        DispatchQueue.main.async {
            self.path.append(destination)
        }
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
