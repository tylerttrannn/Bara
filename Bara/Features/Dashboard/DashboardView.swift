import SwiftUI
import DeviceActivity
import _DeviceActivity_SwiftUI
import Toasts

struct DashboardView: View {
    private enum ResolveAction {
        case approve
        case deny
    }

    @StateObject private var viewModel: DashboardViewModel
    @State private var lastResolveAction: ResolveAction?
    @State private var showUnpairConfirmation = false
    @Environment(\.presentToast) private var presentToast

    init(
        service: PetStateProviding,
        buddyService: BuddyProviding = BuddyServiceFactory.makeDefault(),
        allowanceStore: BorrowAllowanceProviding = AppGroupBorrowAllowanceStore()
    ) {
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(
                service: service,
                buddyService: buddyService,
                allowanceStore: allowanceStore
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(title: "Loading capybara...")
                case .error(let message):
                    ErrorStateView(message: message, buttonTitle: "Retry") {
                        Task { await viewModel.refresh() }
                    }
                case .loaded(let snapshot):
                    ScrollView {
                        VStack(spacing: Spacing.small) {
                            PetHeroCardView(mood: snapshot.mood, description: snapshot.moodDescription)

                            HPProgressCardView(hp: snapshot.hp)

                            DeviceActivityReport(.totalActivity, filter: todayActivityFilter)
                                .frame(height: 120, alignment: .top)

                            buddySection
                        }
                        .padding(Spacing.medium)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Bara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("dashboard.refresh")
                }
            }
        }
        .addToastSafeAreaObserver()
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.pairSubmitState) { _, newState in
            switch newState {
            case .success:
                Haptics.notify(.success)
                presentToast(ToastFactory.make(kind: .success, message: "Buddy paired successfully."))
            case .error(let message):
                Haptics.notify(.error)
                presentToast(ToastFactory.make(kind: .error, message: message))
            case .idle, .loading:
                break
            }
        }
        .onChange(of: viewModel.requestSubmitState) { _, newState in
            switch newState {
            case .success:
                Haptics.notify(.success)
                presentToast(ToastFactory.make(kind: .success, message: "Request sent to your buddy."))
            case .error(let message):
                Haptics.notify(.error)
                presentToast(ToastFactory.make(kind: .error, message: message))
            case .idle, .loading:
                break
            }
        }
        .onChange(of: viewModel.resolveState) { _, newState in
            switch newState {
            case .success:
                let message = lastResolveAction == .approve ? "Request approved." : "Request denied."
                Haptics.notify(lastResolveAction == .approve ? .success : .warning)
                presentToast(ToastFactory.make(kind: .success, message: message))
                lastResolveAction = nil
            case .error(let message):
                Haptics.notify(.error)
                presentToast(ToastFactory.make(kind: .error, message: message))
                lastResolveAction = nil
            case .idle, .loading:
                break
            }
        }
        .onChange(of: viewModel.unpairState) { _, newState in
            switch newState {
            case .success:
                Haptics.notify(.success)
                presentToast(ToastFactory.make(kind: .success, message: "Unpaired"))
            case .error(let message):
                Haptics.notify(.error)
                presentToast(ToastFactory.make(kind: .error, message: message))
            case .idle, .loading:
                break
            }
        }
        .onChange(of: viewModel.newlyApprovedOutgoingRequest) { _, approvedRequest in
            guard let approvedRequest else { return }
            Haptics.notify(.success)
            presentToast(
                ToastFactory.make(
                    kind: .success,
                    message: "Buddy approved \(approvedRequest.minutesRequested) extra minutes."
                )
            )
        }
        .confirmationDialog(
            "Unpair buddy?",
            isPresented: $showUnpairConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unpair Buddy", role: .destructive) {
                Haptics.impact(.medium)
                Task { await viewModel.unpairBuddy() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will unlink both users and expire pending buddy requests.")
        }
    }

    private var buddySection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .center) {
                Text("Buddy Time Exchange")
                    .font(AppTypography.subtitle)
                Spacer()
                buddyStatusBadge
            }

            IncomingBuddyRequestCardView(
                request: viewModel.incomingPendingRequest,
                isResolving: viewModel.resolveState.isLoading,
                resolveError: viewModel.resolveState.errorMessage,
                onDeny: {
                    lastResolveAction = .deny
                    Task { await viewModel.denyIncomingRequest() }
                },
                onApprove: {
                    lastResolveAction = .approve
                    Task { await viewModel.approveIncomingRequest() }
                }
            )

            RequestMoreTimeCardView(
                profile: viewModel.buddyProfile,
                selectedMinutes: viewModel.selectedRequestMinutes,
                note: viewModel.requestNote,
                inviteCode: viewModel.inviteCode,
                pendingOutgoingRequest: viewModel.pendingOutgoingRequest,
                submitState: viewModel.requestSubmitState,
                pairState: viewModel.pairSubmitState,
                unpairState: viewModel.unpairState,
                disabledReason: viewModel.requestDisabledReason,
                onSelectMinutes: { viewModel.selectedRequestMinutes = $0 },
                onNoteChange: { value in
                    viewModel.requestNote = String(value.prefix(BorrowRequestDraft.maxNoteLength))
                },
                onInviteCodeChange: { value in
                    viewModel.inviteCode = String(value.prefix(16))
                },
                onPair: {
                    Task { await viewModel.pairWithInviteCode() }
                },
                onUnpair: {
                    showUnpairConfirmation = true
                },
                onSubmit: {
                    Task { await viewModel.submitBorrowRequest() }
                }
            )

            if let buddySectionError = viewModel.buddySectionError {
                Text(buddySectionError)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var buddyStatusBadge: some View {
        let isLoaded = viewModel.buddyProfile != nil
        let isPaired = viewModel.buddyProfile?.isPaired == true

        let title = isLoaded ? (isPaired ? "Paired" : "Unpaired") : "Checking"
        let icon = isLoaded ? (isPaired ? "link.circle.fill" : "link.badge.plus") : "clock"
        let tint: Color = isLoaded ? (isPaired ? AppColors.accentGreen : AppColors.moodDistressed) : .secondary

        return HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(AppTypography.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(tint.opacity(0.14))
        )
    }

    private var todayActivityFilter: DeviceActivityFilter {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        let dayInterval = DateInterval(start: startOfDay, end: endOfDay)

        return DeviceActivityFilter(
            segment: .daily(during: dayInterval)
        )
    }
}
