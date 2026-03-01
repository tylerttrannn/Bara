import Foundation

enum BorrowRequestStatus: String, Codable, CaseIterable {
    case pending
    case approved
    case denied
    case expired
    case consumed
}

enum BorrowRequestDecision: Equatable {
    case approve
    case deny

    var resultingStatus: BorrowRequestStatus {
        switch self {
        case .approve:
            return .approved
        case .deny:
            return .denied
        }
    }
}

struct BorrowRequest: Identifiable, Equatable, Codable {
    let id: UUID
    let requesterID: UUID
    let buddyID: UUID
    let minutesRequested: Int
    let note: String?
    let status: BorrowRequestStatus
    let createdAt: Date
    let resolvedAt: Date?
    let expiresAt: Date

    var requesterDisplayName: String?
    var buddyDisplayName: String?

    var isExpired: Bool {
        status == .pending && expiresAt <= Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case buddyID = "buddy_id"
        case minutesRequested = "minutes_requested"
        case note
        case status
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
        case expiresAt = "expires_at"
    }
}
