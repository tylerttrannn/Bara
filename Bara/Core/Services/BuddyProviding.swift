import Foundation

protocol BuddyProviding {
    func fetchMyProfile() async throws -> BuddyProfile
    func pairWithInviteCode(_ code: String) async throws -> BuddyProfile
    func unpairCurrentBuddy() async throws -> BuddyProfile
    func resetDemoState() async throws -> BuddyProfile

    func createBorrowRequest(minutes: Int, note: String?) async throws -> BorrowRequest
    func fetchLatestIncomingPendingRequest() async throws -> BorrowRequest?
    func fetchLatestOutgoingPendingRequest() async throws -> BorrowRequest?
    func fetchLatestOutgoingRequest() async throws -> BorrowRequest?

    func observeLatestIncomingPendingRequest() -> AsyncStream<Result<BorrowRequest?, Error>>
    func observeLatestOutgoingRequest() -> AsyncStream<Result<BorrowRequest?, Error>>

    func resolveRequest(id: UUID, decision: BorrowRequestDecision) async throws -> BorrowRequest
}

enum BuddyServiceError: LocalizedError {
    case notPaired
    case alreadyUnpaired
    case invalidInviteCode
    case outgoingRequestAlreadyPending
    case requestExpired
    case forbidden
    case missingConfiguration
    case resetFailed
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notPaired:
            return "Pair with a buddy first."
        case .alreadyUnpaired:
            return "You are already unpaired."
        case .invalidInviteCode:
            return "Invite code not found."
        case .outgoingRequestAlreadyPending:
            return "You already have a pending request."
        case .requestExpired:
            return "That request expired."
        case .forbidden:
            return "You are not allowed to perform that action."
        case .missingConfiguration:
            return "Supabase is not configured yet."
        case .resetFailed:
            return "Could not reset demo state right now."
        case .server(let message):
            return message
        }
    }
}
