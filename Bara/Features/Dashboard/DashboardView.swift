import SwiftUI
import DeviceActivity
import _DeviceActivity_SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

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
        .task {
            await viewModel.load()
        }
    }

    private var buddySection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Buddy Time Exchange")
                .font(AppTypography.subtitle)

            IncomingBuddyRequestCardView(
                request: viewModel.incomingPendingRequest,
                isResolving: viewModel.resolveState.isLoading,
                resolveError: viewModel.resolveState.errorMessage,
                onDeny: {
                    Task { await viewModel.denyIncomingRequest() }
                },
                onApprove: {
                    Task { await viewModel.approveIncomingRequest() }
                }
            )

            RequestMoreTimeCardView(
                profile: viewModel.buddyProfile,
                selectedMinutes: viewModel.selectedRequestMinutes,
                note: viewModel.requestNote,
                inviteCode: viewModel.inviteCode,
                approvalsUsedToday: viewModel.approvalsUsedToday,
                pendingOutgoingRequest: viewModel.pendingOutgoingRequest,
                submitState: viewModel.requestSubmitState,
                pairState: viewModel.pairSubmitState,
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
