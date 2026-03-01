import Foundation
import Testing
@testable import Bara

@MainActor
struct BaraTests {

    @Test
    func dashboardViewModelTransitionsToLoaded() async {
        let vm = DashboardViewModel(
            service: SuccessfulService(),
            buddyService: StubBuddyService.unpaired(),
            allowanceStore: NoopAllowanceStore()
        )

        #expect(stateLabel(vm.state) == "idle")
        await vm.load()
        #expect(stateLabel(vm.state) == "loaded")
    }

    @Test
    func dashboardViewModelTransitionsToError() async {
        let vm = DashboardViewModel(
            service: FailingService(),
            buddyService: StubBuddyService.unpaired(),
            allowanceStore: NoopAllowanceStore()
        )

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

    @Test
    func borrowDraftRejectsNonPresetMinutes() {
        let draft = BorrowRequestDraft(minutes: 12, note: "")
        #expect(throws: BorrowDraftValidationError.self) {
            try draft.validate()
        }
    }

    @Test
    func dashboardDisablesSubmitWhenNotPaired() async {
        let vm = DashboardViewModel(
            service: SuccessfulService(),
            buddyService: StubBuddyService.unpaired(),
            allowanceStore: NoopAllowanceStore()
        )

        await vm.refreshBuddySection()

        #expect(vm.requestDisabledReason == "Pair with a buddy to request more time.")
        #expect(vm.canSubmitRequest == false)
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

private final class StubBuddyService: BuddyProviding {
    private let profile: BuddyProfile
    private var incoming: BorrowRequest?
    private var outgoing: BorrowRequest?
    private let approvalsUsed: Int

    init(
        profile: BuddyProfile,
        incoming: BorrowRequest? = nil,
        outgoing: BorrowRequest? = nil,
        approvalsUsed: Int = 0
    ) {
        self.profile = profile
        self.incoming = incoming
        self.outgoing = outgoing
        self.approvalsUsed = approvalsUsed
    }

    static func unpaired() -> StubBuddyService {
        StubBuddyService(
            profile: BuddyProfile(
                id: UUID(),
                displayName: "Tester",
                inviteCode: "ABC123",
                buddyID: nil,
                points: 0,
                health: 100,
                buddyDisplayName: nil
            )
        )
    }

    func fetchMyProfile() async throws -> BuddyProfile {
        profile
    }

    func pairWithInviteCode(_ code: String) async throws -> BuddyProfile {
        profile
    }

    func createBorrowRequest(minutes: Int, note: String?) async throws -> BorrowRequest {
        let request = BorrowRequest(
            id: UUID(),
            requesterID: profile.id,
            buddyID: profile.buddyID ?? UUID(),
            minutesRequested: minutes,
            note: note,
            status: .pending,
            createdAt: Date(),
            resolvedAt: nil,
            expiresAt: Date().addingTimeInterval(300),
            requesterDisplayName: profile.displayName,
            buddyDisplayName: profile.buddyDisplayName
        )
        outgoing = request
        return request
    }

    func fetchLatestIncomingPendingRequest() async throws -> BorrowRequest? {
        incoming
    }

    func fetchLatestOutgoingPendingRequest() async throws -> BorrowRequest? {
        outgoing?.status == .pending ? outgoing : nil
    }

    func fetchLatestOutgoingRequest() async throws -> BorrowRequest? {
        outgoing
    }

    func observeLatestIncomingPendingRequest() -> AsyncStream<Result<BorrowRequest?, Error>> {
        AsyncStream { continuation in
            continuation.yield(.success(incoming))
            continuation.finish()
        }
    }

    func observeLatestOutgoingRequest() -> AsyncStream<Result<BorrowRequest?, Error>> {
        AsyncStream { continuation in
            continuation.yield(.success(outgoing))
            continuation.finish()
        }
    }

    func resolveRequest(id: UUID, decision: BorrowRequestDecision) async throws -> BorrowRequest {
        let resolved = BorrowRequest(
            id: id,
            requesterID: incoming?.requesterID ?? profile.id,
            buddyID: profile.id,
            minutesRequested: incoming?.minutesRequested ?? 10,
            note: incoming?.note,
            status: decision.resultingStatus,
            createdAt: incoming?.createdAt ?? Date(),
            resolvedAt: Date(),
            expiresAt: Date().addingTimeInterval(300),
            requesterDisplayName: incoming?.requesterDisplayName,
            buddyDisplayName: profile.displayName
        )
        incoming = nil
        return resolved
    }

    func fetchApprovalsUsedToday() async throws -> Int {
        approvalsUsed
    }
}

private struct NoopAllowanceStore: BorrowAllowanceProviding {
    func activeAllowance(now: Date) -> BorrowAllowance? { nil }
    func storeAllowance(_ allowance: BorrowAllowance) {}
    func consumeAllowance() {}
    func clearAllowance() {}
}
