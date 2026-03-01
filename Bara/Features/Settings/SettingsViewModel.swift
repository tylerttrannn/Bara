import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
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

    @Published private(set) var settings: SettingsState
    @Published private(set) var buddyProfile: BuddyProfile?
    @Published private(set) var unpairState: AsyncActionState = .idle
    @Published private(set) var resetState: AsyncActionState = .idle

    private let service: PetStateProviding
    private let buddyService: BuddyProviding
    private let allowanceStore: BorrowAllowanceProviding
    private let scheduleLimits: ScheduleLimits
    private let defaults: UserDefaults
    private var profilePollingTask: Task<Void, Never>?
    private var isProfilePollingStarted = false

    init(
        service: PetStateProviding,
        buddyService: BuddyProviding = BuddyServiceFactory.makeDefault(),
        allowanceStore: BorrowAllowanceProviding = AppGroupBorrowAllowanceStore(),
        defaults: UserDefaults = AppGroupDefaults.sharedDefaults
    ) {
        self.service = service
        self.buddyService = buddyService
        self.allowanceStore = allowanceStore
        self.defaults = defaults
        self.scheduleLimits = ScheduleLimits(defaults: defaults, allowanceStore: allowanceStore)
        self.settings = service.fetchSettingsState()
    }

    deinit {
        profilePollingTask?.cancel()
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

    func loadBuddyProfile() async {
        do {
            buddyProfile = try await buddyService.fetchMyProfile()
        } catch {
            // Keep the previous visible state if a transient poll fails.
        }

        startProfilePollingIfNeeded()
    }

    func unpairBuddy() async {
        guard buddyProfile?.isPaired == true else {
            unpairState = .error(BuddyServiceError.alreadyUnpaired.localizedDescription)
            return
        }

        unpairState = .loading

        do {
            buddyProfile = try await buddyService.unpairCurrentBuddy()
            unpairState = .success
        } catch {
            unpairState = .error(ToastFactory.userMessage(from: error))
        }
    }

    func resetDemoState() async {
        resetState = .loading

        do {
            buddyProfile = try await buddyService.resetDemoState()
            allowanceStore.clearAllowance()
            AppSelectionModel.clearSelection(defaults: defaults)
            AppGroupDefaults.clearBorrowAndBlockFlags(defaults: defaults)
            AppGroupDefaults.clearFocusSetup(defaults: defaults)
            AppGroupDefaults.markOnboardingIncomplete(defaults: defaults)
            settings.isOnboardingCompleted = false
            resetState = .success
        } catch {
            resetState = .error(ToastFactory.userMessage(from: error))
        }
    }

    private func startProfilePollingIfNeeded() {
        guard !isProfilePollingStarted else { return }
        isProfilePollingStarted = true

        profilePollingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                do {
                    self.buddyProfile = try await buddyService.fetchMyProfile()
                } catch {
                    // Keep last known profile when offline/intermittent.
                }

                try? await Task.sleep(for: .seconds(3))
            }
        }
    }
}
