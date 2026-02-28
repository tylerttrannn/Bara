import Foundation

protocol PetStateProviding {
    func fetchDashboardSnapshot() async throws -> PetSnapshot
    func fetchStatsSnapshot() async throws -> UsageSnapshot
    func fetchSettingsState() -> SettingsState
    func fetchDistractionPreferences() -> DistractionPreferences
    func saveDistractionPreferences(_ preferences: DistractionPreferences)
    func setOnboardingCompleted(_ completed: Bool)
}
