import Foundation

final class MockPetStateService: PetStateProviding {
    private let lock = NSLock()
    private var settings: SettingsState

    init(settings: SettingsState = SettingsState(isOnboardingCompleted: false, notificationsEnabled: true, permissionGranted: true)) {
        self.settings = settings
    }

    func fetchDashboardSnapshot() async throws -> PetSnapshot {
        try await Task.sleep(for: .milliseconds(250))

        return PetSnapshot(
            hp: 72,
            mood: .happy,
            distractingMinutesToday: 96,
            moodDescription: "Capy is okay, but could use a calmer day.",
            updatedAt: Date()
        )
    }

    func fetchStatsSnapshot() async throws -> UsageSnapshot {
        try await Task.sleep(for: .milliseconds(200))

        return UsageSnapshot(
            todayMinutes: 96,
            weeklyAverageMinutes: 83,
            trend: [
                DayUsagePoint(dayLabel: "Mon", minutes: 74),
                DayUsagePoint(dayLabel: "Tue", minutes: 68),
                DayUsagePoint(dayLabel: "Wed", minutes: 102),
                DayUsagePoint(dayLabel: "Thu", minutes: 89),
                DayUsagePoint(dayLabel: "Fri", minutes: 120),
                DayUsagePoint(dayLabel: "Sat", minutes: 96),
                DayUsagePoint(dayLabel: "Sun", minutes: 63)
            ],
            categoryBreakdown: [
                CategoryUsage(name: "Social", minutes: 44),
                CategoryUsage(name: "Streaming", minutes: 29),
                CategoryUsage(name: "Games", minutes: 17),
                CategoryUsage(name: "Shopping", minutes: 6)
            ]
        )
    }

    func fetchSettingsState() -> SettingsState {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }

    func setOnboardingCompleted(_ completed: Bool) {
        lock.lock()
        settings.isOnboardingCompleted = completed
        lock.unlock()
    }
}
