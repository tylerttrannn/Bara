import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    enum AsyncActionState: Equatable {
        case idle
        case loading
        case success
        case error(String)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        var errorMessage: String? {
            if case .error(let message) = self {
                return message
            }
            return nil
        }
    }

    @Published private(set) var state: ViewState<PetSnapshot> = .idle

    @Published private(set) var buddyProfile: BuddyProfile?
    @Published private(set) var incomingPendingRequest: BorrowRequest?
    @Published private(set) var latestOutgoingRequest: BorrowRequest?
    @Published private(set) var approvalsUsedToday: Int = 0

    @Published var selectedRequestMinutes: Int = BorrowRequestDraft.allowedMinutes[2]
    @Published var requestNote: String = "" {
        didSet {
            if requestNote.count > BorrowRequestDraft.maxNoteLength {
                requestNote = String(requestNote.prefix(BorrowRequestDraft.maxNoteLength))
            }
            recalculateRequestDisabledReason()
        }
    }
    @Published var inviteCode: String = ""

    @Published private(set) var requestSubmitState: AsyncActionState = .idle
    @Published private(set) var pairSubmitState: AsyncActionState = .idle
    @Published private(set) var resolveState: AsyncActionState = .idle
    @Published private(set) var buddySectionError: String?
    @Published private(set) var requestDisabledReason: String?

    var canSubmitRequest: Bool {
        requestDisabledReason == nil && !requestSubmitState.isLoading
    }

    var pendingOutgoingRequest: BorrowRequest? {
        guard let latestOutgoingRequest, latestOutgoingRequest.status == .pending else {
            return nil
        }
        return latestOutgoingRequest
    }

    private let service: PetStateProviding
    private let buddyService: BuddyProviding
    private let allowanceStore: BorrowAllowanceProviding
    private let scheduleLimits: ScheduleLimits
    private let defaults: UserDefaults

    private var incomingObserverTask: Task<Void, Never>?
    private var outgoingObserverTask: Task<Void, Never>?
    private var observersStarted = false

    init(
        service: PetStateProviding,
        buddyService: BuddyProviding = BuddyServiceFactory.makeDefault(),
        allowanceStore: BorrowAllowanceProviding = AppGroupBorrowAllowanceStore(),
        scheduleLimits: ScheduleLimits? = nil,
        defaults: UserDefaults = AppGroupDefaults.sharedDefaults
    ) {
        self.service = service
        self.buddyService = buddyService
        self.allowanceStore = allowanceStore
        self.defaults = defaults
        self.scheduleLimits = scheduleLimits ?? ScheduleLimits(defaults: defaults, allowanceStore: allowanceStore)
    }

    deinit {
        incomingObserverTask?.cancel()
        outgoingObserverTask?.cancel()
    }

    func load() async {
        guard case .idle = state else {
            startObserversIfNeeded()
            await refreshBuddySection()
            return
        }

        await refresh()
    }

    func refresh() async {
        state = .loading

        do {
            let snapshot = try await service.fetchDashboardSnapshot()
            state = .loaded(snapshot)
        } catch {
            state = .error("Could not load capybara status right now.")
        }

        await refreshBuddySection()
        startObserversIfNeeded()
    }

    func refreshBuddySection() async {
        buddySectionError = nil

        do {
            async let profileTask = buddyService.fetchMyProfile()
            async let incomingTask = buddyService.fetchLatestIncomingPendingRequest()
            async let outgoingTask = buddyService.fetchLatestOutgoingRequest()
            async let approvalsTask = buddyService.fetchApprovalsUsedToday()

            let profile = try await profileTask
            buddyProfile = profile
            syncScoreCache(with: profile)

            incomingPendingRequest = try await incomingTask
            latestOutgoingRequest = try await outgoingTask
            approvalsUsedToday = try await approvalsTask

            applyAllowanceIfApprovedOutgoingExists()
        } catch {
            buddySectionError = error.localizedDescription
        }

        recalculateRequestDisabledReason()
    }

    func pairWithInviteCode() async {
        let rawCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawCode.isEmpty else {
            pairSubmitState = .error("Enter your buddy's invite code.")
            return
        }

        pairSubmitState = .loading

        do {
            let updatedProfile = try await buddyService.pairWithInviteCode(rawCode)
            buddyProfile = updatedProfile
            syncScoreCache(with: updatedProfile)
            inviteCode = ""
            pairSubmitState = .success
            await refreshBuddySection()
        } catch {
            pairSubmitState = .error(error.localizedDescription)
        }
    }

    func submitBorrowRequest() async {
        guard canSubmitRequest else {
            requestSubmitState = .error(requestDisabledReason ?? "Cannot submit right now.")
            return
        }

        let draft = BorrowRequestDraft(minutes: selectedRequestMinutes, note: requestNote)

        do {
            try draft.validate()
        } catch {
            requestSubmitState = .error(error.localizedDescription)
            return
        }

        requestSubmitState = .loading

        do {
            let request = try await buddyService.createBorrowRequest(
                minutes: selectedRequestMinutes,
                note: draft.normalizedNote
            )

            latestOutgoingRequest = request
            requestNote = ""
            requestSubmitState = .success
            await refreshBuddySection()
        } catch {
            requestSubmitState = .error(error.localizedDescription)
            recalculateRequestDisabledReason()
        }
    }

    func approveIncomingRequest() async {
        await resolveIncomingRequest(with: .approve)
    }

    func denyIncomingRequest() async {
        await resolveIncomingRequest(with: .deny)
    }

    private func resolveIncomingRequest(with decision: BorrowRequestDecision) async {
        guard let incomingPendingRequest else {
            return
        }

        resolveState = .loading

        do {
            _ = try await buddyService.resolveRequest(id: incomingPendingRequest.id, decision: decision)
            resolveState = .success
            await refreshBuddySection()
        } catch {
            resolveState = .error(error.localizedDescription)
        }
    }

    private func startObserversIfNeeded() {
        guard !observersStarted else { return }
        observersStarted = true

        incomingObserverTask = Task { [weak self] in
            guard let self else { return }

            for await result in buddyService.observeLatestIncomingPendingRequest() {
                guard !Task.isCancelled else { return }

                switch result {
                case .success(let request):
                    self.incomingPendingRequest = request
                    self.resolveState = .idle
                    self.recalculateRequestDisabledReason()
                case .failure(let error):
                    self.buddySectionError = error.localizedDescription
                }
            }
        }

        outgoingObserverTask = Task { [weak self] in
            guard let self else { return }

            for await result in buddyService.observeLatestOutgoingRequest() {
                guard !Task.isCancelled else { return }

                switch result {
                case .success(let request):
                    self.latestOutgoingRequest = request
                    self.applyAllowanceIfApprovedOutgoingExists()
                    self.recalculateRequestDisabledReason()
                case .failure(let error):
                    self.buddySectionError = error.localizedDescription
                }
            }
        }
    }

    private func applyAllowanceIfApprovedOutgoingExists() {
        guard let latestOutgoingRequest, latestOutgoingRequest.status == .approved else {
            return
        }

        if defaults.string(forKey: AppGroupDefaults.lastAppliedBorrowRequestID) == latestOutgoingRequest.id.uuidString {
            return
        }

        let approvalTime = latestOutgoingRequest.resolvedAt ?? Date()
        let allowance = BorrowAllowance(
            minutes: latestOutgoingRequest.minutesRequested,
            approvedAt: approvalTime,
            expiresAt: endOfDay(from: approvalTime),
            consumed: false
        )

        allowanceStore.storeAllowance(allowance)
        defaults.set(latestOutgoingRequest.id.uuidString, forKey: AppGroupDefaults.lastAppliedBorrowRequestID)
        scheduleLimits.activateBorrowAllowanceIfAvailable()
    }

    private func recalculateRequestDisabledReason() {
        if requestNote.trimmingCharacters(in: .whitespacesAndNewlines).count > BorrowRequestDraft.maxNoteLength {
            requestDisabledReason = "Message must be 120 characters or less."
            return
        }

        guard let buddyProfile else {
            requestDisabledReason = "Loading buddy status..."
            return
        }

        guard buddyProfile.isPaired else {
            requestDisabledReason = "Pair with a buddy to request more time."
            return
        }

        if pendingOutgoingRequest != nil {
            requestDisabledReason = "You already have a pending outgoing request."
            return
        }

        if approvalsUsedToday >= 2 {
            requestDisabledReason = "Daily cap reached (2 approved requests today)."
            return
        }

        requestDisabledReason = nil
    }

    private func syncScoreCache(with profile: BuddyProfile) {
        AppGroupDefaults.setCachedHealthValue(profile.health, defaults: defaults)
        AppGroupDefaults.setCachedPointsValue(profile.points, defaults: defaults)
    }

    private func endOfDay(from date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date.addingTimeInterval(24 * 60 * 60)
    }
}
