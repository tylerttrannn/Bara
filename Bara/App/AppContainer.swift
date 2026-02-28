import Foundation

final class AppContainer {
    let petStateService: PetStateProviding

    init(petStateService: PetStateProviding) {
        self.petStateService = petStateService
    }

    static func live() -> AppContainer {
        let shouldSkipOnboarding = ProcessInfo.processInfo.arguments.contains("UITEST_SKIP_ONBOARDING")
        let service = LivePetStateService(
            forceOnboardingCompleted: shouldSkipOnboarding ? true : nil
        )

        return AppContainer(petStateService: service)
    }
}
