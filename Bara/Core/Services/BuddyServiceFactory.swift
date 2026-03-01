import Foundation

enum BuddyServiceFactory {
    static func makeDefault(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) -> BuddyProviding {
        if let config = SupabaseConfig.load(defaults: defaults) {
            return SupabaseBuddyService(config: config, defaults: defaults)
        }

        return LocalBuddyService(defaults: defaults)
    }
}
