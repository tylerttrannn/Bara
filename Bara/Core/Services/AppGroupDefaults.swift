import Foundation

enum AppGroupDefaults {
    static let suiteName = "group.com.Bara.appblocker"

    static let onboardingCompleted = "bara.onboarding.completed"
    static let thresholdMinutes = "bara.threshold.minutes"
    static let selectedAppIDs = "bara.distractions.selectedAppIDs"

    static let legacyHealth = "bara.pet.hp"
    static let cachedHealth = "bara.user.health.cached"
    static let cachedPoints = "bara.user.points.cached"

    static let localUserID = "bara.user.id"
    static let localDisplayName = "bara.user.displayName"
    static let localInviteCode = "bara.user.inviteCode"
    static let lastAppliedBorrowRequestID = "bara.borrow.allowance.lastAppliedRequestID"

    static let borrowAllowanceMinutes = "bara.borrow.allowance.minutes"
    static let borrowAllowanceApprovedAt = "bara.borrow.allowance.approvedAt"
    static let borrowAllowanceExpiresAt = "bara.borrow.allowance.expiresAt"
    static let borrowAllowanceConsumed = "bara.borrow.allowance.consumed"

    static let supabaseURL = "bara.supabase.url"
    static let supabaseAnonKey = "bara.supabase.anonKey"
    static let supabaseAuthToken = "bara.supabase.authToken"
    static let defaultSupabaseURL = "https://nquvweyejkluoxnpyubr.supabase.co"
    static let defaultSupabaseAnonKey = "sb_publishable_0-DwUmg2BcrqLYSm5Ym6Xw_aqsDhi2N"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func ensureLocalUserID(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) -> UUID {
        if let raw = defaults.string(forKey: localUserID), let id = UUID(uuidString: raw) {
            return id
        }

        let generated = UUID()
        defaults.set(generated.uuidString, forKey: localUserID)
        return generated
    }

    static func cachedHealthValue(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) -> Int {
        if defaults.object(forKey: cachedHealth) != nil {
            return max(0, min(defaults.integer(forKey: cachedHealth), 100))
        }

        let legacy = defaults.object(forKey: legacyHealth) != nil ? defaults.double(forKey: legacyHealth) : 100
        let normalized = max(0, min(Int(legacy.rounded()), 100))
        defaults.set(normalized, forKey: cachedHealth)
        return normalized
    }

    static func setCachedHealthValue(_ value: Int, defaults: UserDefaults = AppGroupDefaults.sharedDefaults) {
        let normalized = max(0, min(value, 100))
        defaults.set(normalized, forKey: cachedHealth)
        defaults.set(Double(normalized), forKey: legacyHealth)
    }

    static func cachedPointsValue(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) -> Int {
        defaults.integer(forKey: cachedPoints)
    }

    static func setCachedPointsValue(_ value: Int, defaults: UserDefaults = AppGroupDefaults.sharedDefaults) {
        defaults.set(max(0, value), forKey: cachedPoints)
    }
}
