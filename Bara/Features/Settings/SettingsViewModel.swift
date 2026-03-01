import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: SettingsState

    private let service: PetStateProviding
    private let scheduleLimits = ScheduleLimits()
    private let defaults = AppGroupDefaults.sharedDefaults

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

    func startActivityLimitTest() {
        scheduleLimits.startActivity()
    }

    func triggerBlockNow() {
        defaults.set(false, forKey: AppGroupDefaults.unblockNow)
        defaults.set(true, forKey: AppGroupDefaults.blockNow)
        scheduleLimits.startActivity()
    }

    func triggerUnblockNow() {
        defaults.set(false, forKey: AppGroupDefaults.blockNow)
        defaults.set(true, forKey: AppGroupDefaults.unblockNow)
        scheduleLimits.startActivity()
    }
}
