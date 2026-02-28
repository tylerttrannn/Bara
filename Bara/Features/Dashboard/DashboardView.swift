import SwiftUI

struct DashboardView: View {
    private let service: PetStateProviding
    @StateObject private var viewModel: DashboardViewModel

    init(service: PetStateProviding) {
        self.service = service
        _viewModel = StateObject(wrappedValue: DashboardViewModel(service: service))
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
                        VStack(spacing: Spacing.medium) {
                            PetHeroCardView(mood: snapshot.mood, description: snapshot.moodDescription)

                            HPProgressCardView(hp: snapshot.hp)

                            distractingTimeCard(minutes: snapshot.distractingMinutesToday)

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
                    colors: [AppColors.sandBackground, Color.white],
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

    private func distractingTimeCard(minutes: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Today's distracting time")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            Text("\(minutes)m")
                .font(AppTypography.title)
            Text("Keep it low to cheer up Bara.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

#Preview("Loaded") {
    PreviewContainer {
        DashboardView(service: MockPetStateService(settings: SettingsState(isOnboardingCompleted: true, notificationsEnabled: true, permissionGranted: true)))
    }
}
