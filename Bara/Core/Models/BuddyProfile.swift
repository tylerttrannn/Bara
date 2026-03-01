import Foundation

struct BuddyProfile: Identifiable, Equatable, Codable {
    let id: UUID
    var displayName: String
    var inviteCode: String
    var buddyID: UUID?
    var points: Int
    var health: Int
    var buddyDisplayName: String?

    var isPaired: Bool {
        buddyID != nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case inviteCode = "invite_code"
        case buddyID = "buddy_id"
        case points
        case health
    }
}
