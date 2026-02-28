import Foundation

final class AppContainer {
    let petStateService: PetStateProviding

    init(petStateService: PetStateProviding) {
        self.petStateService = petStateService
    }

    static func live() -> AppContainer {
        let shouldSkipOnboarding = ProcessInfo.processInfo.arguments.contains("UITEST_SKIP_ONBOARDING")
        let service = MockPetStateService(
            settings: SettingsState(
                isOnboardingCompleted: shouldSkipOnboarding,
                notificationsEnabled: true,
                permissionGranted: true
            )
        )

        return AppContainer(petStateService: service)
    }
}
