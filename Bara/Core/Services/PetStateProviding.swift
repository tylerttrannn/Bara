import Foundation

protocol PetStateProviding {
    func fetchDashboardSnapshot() async throws -> PetSnapshot
    func fetchStatsSnapshot() async throws -> UsageSnapshot
    func fetchSettingsState() -> SettingsState
    func setOnboardingCompleted(_ completed: Bool)
}
