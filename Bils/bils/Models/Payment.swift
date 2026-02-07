import Foundation

struct Payment: Identifiable, Codable {
    let id: UUID
    let merchant: String
    let amount: Double
    let date: Date
    let category: PaymentCategory
    var splitStatus: SplitStatus

    init(
        id: UUID = UUID(),
        merchant: String,
        amount: Double,
        date: Date = Date(),
        category: PaymentCategory = .restaurant,
        splitStatus: SplitStatus = .pending
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.date = date
        self.category = category
        self.splitStatus = splitStatus
    }
}

enum PaymentCategory: String, Codable, CaseIterable {
    case restaurant = "Restaurant"
    case groceries = "Groceries"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case other = "Other"

    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .groceries: return "cart"
        case .utilities: return "bolt"
        case .entertainment: return "film"
        case .other: return "ellipsis.circle"
        }
    }
}

enum SplitStatus: String, Codable {
    case pending = "Pending"
    case splitEvenly = "Split Evenly"
    case customSplit = "Custom Split"
    case ignored = "Ignored"
}
