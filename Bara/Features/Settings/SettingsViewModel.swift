import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: SettingsState

    private let service: PetStateProviding

    init(service: PetStateProviding) {
        self.service = service
        self.settings = service.fetchSettingsState()
    }

    func setNotifications(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
    }

    func completeOnboarding(_ completed: Bool) {
        service.setOnboardingCompleted(completed)
        settings.isOnboardingCompleted = completed
    }

    func markPermission(enabled: Bool) {
        settings.permissionGranted = enabled
    }
}
