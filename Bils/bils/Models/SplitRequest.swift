import Foundation

struct SplitParticipant: Identifiable, Codable {
    let id: UUID
    let presetID: UUID
    var nameSnapshot: String
    var amountOwed: Double
    var status: SplitParticipantStatus

    init(
        id: UUID = UUID(),
        presetID: UUID,
        nameSnapshot: String,
        amountOwed: Double,
        status: SplitParticipantStatus = .requested
    ) {
        self.id = id
        self.presetID = presetID
        self.nameSnapshot = nameSnapshot
        self.amountOwed = amountOwed
        self.status = status
    }
}

struct SplitRequest: Identifiable, Codable {
    let id: UUID
    let paymentID: UUID
    let merchant: String
    let totalAmount: Double
    let createdAt: Date
    let direction: SplitDirection
    var note: String
    var participants: [SplitParticipant]
    var status: SplitRequestStatus

    init(
        id: UUID = UUID(),
        paymentID: UUID,
        merchant: String,
        totalAmount: Double,
        createdAt: Date = Date(),
        direction: SplitDirection,
        note: String = "",
        participants: [SplitParticipant],
        status: SplitRequestStatus = .unresolved
    ) {
        self.id = id
        self.paymentID = paymentID
        self.merchant = merchant
        self.totalAmount = totalAmount
        self.createdAt = createdAt
        self.direction = direction
        self.note = note
        self.participants = participants
        self.status = status
    }
}

enum SplitRequestStatus: String, Codable {
    case unresolved = "Unresolved"
    case resolved = "Resolved"
    case canceled = "Canceled"
}

enum SplitParticipantStatus: String, Codable {
    case requested = "Requested"
    case paid = "Paid"
}

enum SplitDirection: String, Codable {
    case outgoing = "Outgoing"
    case incoming = "Incoming"
}
