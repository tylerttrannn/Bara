import Foundation

final class LivePetStateService: PetStateProviding {
    private enum DefaultsKey {
        static let onboardingCompleted = AppGroupDefaults.onboardingCompleted
        static let thresholdMinutes = AppGroupDefaults.thresholdMinutes
        static let selectedAppIDs = AppGroupDefaults.selectedAppIDs
    }

    private let lock = NSLock()
    private var settings: SettingsState
    private let defaults: UserDefaults

    init(
        defaults: UserDefaults = AppGroupDefaults.sharedDefaults,
        forceOnboardingCompleted: Bool? = nil
    ) {
        self.defaults = defaults

        let persistedOnboarding = defaults.object(forKey: DefaultsKey.onboardingCompleted) as? Bool ?? false
        let onboardingCompleted = forceOnboardingCompleted ?? persistedOnboarding

        self.settings = SettingsState(
            isOnboardingCompleted: onboardingCompleted,
            notificationsEnabled: true,
            permissionGranted: true
        )

        if defaults.object(forKey: AppGroupDefaults.cachedHealth) == nil {
            AppGroupDefaults.setCachedHealthValue(100, defaults: defaults)
        }

        if defaults.object(forKey: DefaultsKey.thresholdMinutes) == nil {
            defaults.set(30, forKey: DefaultsKey.thresholdMinutes)
        }
    }

    func fetchDashboardSnapshot() async throws -> PetSnapshot {
        let hp = max(min(Double(AppGroupDefaults.cachedHealthValue(defaults: defaults)), 100), 0)
        let mood = moodForHP(hp)

        return PetSnapshot(
            hp: hp,
            mood: mood,
            distractingMinutesToday: 0,
            moodDescription: moodDescription(for: mood),
            updatedAt: Date()
        )
    }

    func fetchStatsSnapshot() async throws -> UsageSnapshot {
        let trend = recentDayLabels().map { DayUsagePoint(dayLabel: $0, minutes: 0) }

        return UsageSnapshot(
            todayMinutes: 0,
            weeklyAverageMinutes: 0,
            trend: trend,
            categoryBreakdown: []
        )
    }

    func fetchSettingsState() -> SettingsState {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }

    func fetchDistractionPreferences() -> DistractionPreferences {
        let threshold = max(defaults.integer(forKey: DefaultsKey.thresholdMinutes), 5)
        let selectedAppIDs = Set(defaults.stringArray(forKey: DefaultsKey.selectedAppIDs) ?? [])

        return DistractionPreferences(
            selectedAppIDs: selectedAppIDs,
            thresholdMinutes: threshold
        )
    }

    func saveDistractionPreferences(_ preferences: DistractionPreferences) {
        defaults.set(preferences.thresholdMinutes, forKey: DefaultsKey.thresholdMinutes)
        defaults.set(Array(preferences.selectedAppIDs), forKey: DefaultsKey.selectedAppIDs)
    }

    func setOnboardingCompleted(_ completed: Bool) {
        lock.lock()
        settings.isOnboardingCompleted = completed
        lock.unlock()
        defaults.set(completed, forKey: DefaultsKey.onboardingCompleted)
    }

    private func moodForHP(_ hp: Double) -> MoodState {
        switch hp {
        case 80...:
            return .happy
        case 50..<80:
            return .neutral
        case 20..<50:
            return .sad
        default:
            return .distressed
        }
    }

    private func moodDescription(for mood: MoodState) -> String {
        switch mood {
        case .happy:
            return "Bara is thriving. Keep this momentum going."
        case .neutral:
            return "Bara is doing okay. A little more focus helps."
        case .sad:
            return "Bara is feeling drained. Try reducing distractions."
        case .distressed:
            return "Bara is struggling. Time for a focus reset."
        }
    }

    private func recentDayLabels() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEE")

        let calendar = Calendar.current
        let today = Date()

        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return formatter.string(from: day)
        }
    }
}
