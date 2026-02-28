import Foundation
import Testing
@testable import Bara

@MainActor
struct BaraTests {

    @Test
    func dashboardViewModelTransitionsToLoaded() async {
        let vm = DashboardViewModel(service: SuccessfulService())

        #expect(stateLabel(vm.state) == "idle")
        await vm.load()
        #expect(stateLabel(vm.state) == "loaded")
    }

    @Test
    func dashboardViewModelTransitionsToError() async {
        let vm = DashboardViewModel(service: FailingService())

        await vm.refresh()
        #expect(stateLabel(vm.state) == "error")
    }

    @Test
    func settingsToggleUpdatesState() {
        let vm = SettingsViewModel(service: SuccessfulService())
        let original = vm.settings.notificationsEnabled

        vm.setNotifications(!original)

        #expect(vm.settings.notificationsEnabled != original)
    }

    private func stateLabel<T>(_ state: ViewState<T>) -> String {
        switch state {
        case .idle: return "idle"
        case .loading: return "loading"
        case .loaded: return "loaded"
        case .error: return "error"
        }
    }
}

private struct SuccessfulService: PetStateProviding {
    func fetchDashboardSnapshot() async throws -> PetSnapshot {
        PetSnapshot(
            hp: 80,
            mood: .happy,
            distractingMinutesToday: 30,
            moodDescription: "Doing great",
            updatedAt: Date()
        )
    }

    func fetchStatsSnapshot() async throws -> UsageSnapshot {
        UsageSnapshot(
            todayMinutes: 30,
            weeklyAverageMinutes: 40,
            trend: [DayUsagePoint(dayLabel: "Mon", minutes: 30)],
            categoryBreakdown: [CategoryUsage(name: "Social", minutes: 30)]
        )
    }

    func fetchSettingsState() -> SettingsState {
        SettingsState(isOnboardingCompleted: true, notificationsEnabled: true, permissionGranted: true)
    }

    func fetchDistractionPreferences() -> DistractionPreferences {
        .default
    }

    func saveDistractionPreferences(_ preferences: DistractionPreferences) {}

    func setOnboardingCompleted(_ completed: Bool) {}
}

private struct FailingService: PetStateProviding {
    struct MockError: Error {}

    func fetchDashboardSnapshot() async throws -> PetSnapshot {
        throw MockError()
    }

    func fetchStatsSnapshot() async throws -> UsageSnapshot {
        throw MockError()
    }

    func fetchSettingsState() -> SettingsState {
        SettingsState(isOnboardingCompleted: true, notificationsEnabled: true, permissionGranted: false)
    }

    func fetchDistractionPreferences() -> DistractionPreferences {
        .default
    }

    func saveDistractionPreferences(_ preferences: DistractionPreferences) {}

    func setOnboardingCompleted(_ completed: Bool) {}
}
