import Foundation

struct BorrowAllowance: Equatable, Codable {
    let minutes: Int
    let approvedAt: Date
    let expiresAt: Date
    var consumed: Bool

    func isActive(at date: Date = Date()) -> Bool {
        !consumed && minutes > 0 && expiresAt > date
    }
}
