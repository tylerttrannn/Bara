import Foundation

final class AppContainer {
    let petStateService: PetStateProviding
    let buddyService: BuddyProviding
    let allowanceStore: BorrowAllowanceProviding

    init(
        petStateService: PetStateProviding,
        buddyService: BuddyProviding,
        allowanceStore: BorrowAllowanceProviding
    ) {
        self.petStateService = petStateService
        self.buddyService = buddyService
        self.allowanceStore = allowanceStore
    }

    static func live() -> AppContainer {
        let shouldSkipOnboarding = ProcessInfo.processInfo.arguments.contains("UITEST_SKIP_ONBOARDING")
        let defaults = AppGroupDefaults.sharedDefaults

        if defaults.string(forKey: AppGroupDefaults.supabaseURL)?.isEmpty != false {
            defaults.set(AppGroupDefaults.defaultSupabaseURL, forKey: AppGroupDefaults.supabaseURL)
        }

        if defaults.string(forKey: AppGroupDefaults.supabaseAnonKey)?.isEmpty != false {
            defaults.set(AppGroupDefaults.defaultSupabaseAnonKey, forKey: AppGroupDefaults.supabaseAnonKey)
        }

        let allowanceStore = AppGroupBorrowAllowanceStore(defaults: defaults)

        let service = LivePetStateService(
            defaults: defaults,
            forceOnboardingCompleted: shouldSkipOnboarding ? true : nil
        )

        let buddyService = BuddyServiceFactory.makeDefault(defaults: defaults)

        return AppContainer(
            petStateService: service,
            buddyService: buddyService,
            allowanceStore: allowanceStore
        )
    }
}
