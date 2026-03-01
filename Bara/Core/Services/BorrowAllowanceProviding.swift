import Foundation

protocol BorrowAllowanceProviding {
    func activeAllowance(now: Date) -> BorrowAllowance?
    func storeAllowance(_ allowance: BorrowAllowance)
    func consumeAllowance()
    func clearAllowance()
}

final class AppGroupBorrowAllowanceStore: BorrowAllowanceProviding {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) {
        self.defaults = defaults
    }

    func activeAllowance(now: Date = Date()) -> BorrowAllowance? {
        guard defaults.object(forKey: AppGroupDefaults.borrowAllowanceMinutes) != nil else {
            return nil
        }

        let minutes = defaults.integer(forKey: AppGroupDefaults.borrowAllowanceMinutes)
        let consumed = defaults.bool(forKey: AppGroupDefaults.borrowAllowanceConsumed)
        let approvedAt = defaults.object(forKey: AppGroupDefaults.borrowAllowanceApprovedAt) as? Date ?? now
        guard let expiresAt = defaults.object(forKey: AppGroupDefaults.borrowAllowanceExpiresAt) as? Date else {
            clearAllowance()
            return nil
        }

        let allowance = BorrowAllowance(
            minutes: minutes,
            approvedAt: approvedAt,
            expiresAt: expiresAt,
            consumed: consumed
        )

        if allowance.isActive(at: now) {
            return allowance
        }

        clearAllowance()
        return nil
    }

    func storeAllowance(_ allowance: BorrowAllowance) {
        defaults.set(allowance.minutes, forKey: AppGroupDefaults.borrowAllowanceMinutes)
        defaults.set(allowance.approvedAt, forKey: AppGroupDefaults.borrowAllowanceApprovedAt)
        defaults.set(allowance.expiresAt, forKey: AppGroupDefaults.borrowAllowanceExpiresAt)
        defaults.set(allowance.consumed, forKey: AppGroupDefaults.borrowAllowanceConsumed)
    }

    func consumeAllowance() {
        defaults.set(true, forKey: AppGroupDefaults.borrowAllowanceConsumed)
    }

    func clearAllowance() {
        defaults.removeObject(forKey: AppGroupDefaults.borrowAllowanceMinutes)
        defaults.removeObject(forKey: AppGroupDefaults.borrowAllowanceApprovedAt)
        defaults.removeObject(forKey: AppGroupDefaults.borrowAllowanceExpiresAt)
        defaults.removeObject(forKey: AppGroupDefaults.borrowAllowanceConsumed)
    }
}
