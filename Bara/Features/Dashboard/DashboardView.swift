import SwiftUI
import DeviceActivity
import _DeviceActivity_SwiftUI

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

                            DeviceActivityReport(.totalActivity, filter: todayActivityFilter)
                                .frame(height: 170)
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

#Preview("Loaded") {
    PreviewContainer {
        DashboardView(service: MockPetStateService(settings: SettingsState(isOnboardingCompleted: true, notificationsEnabled: true, permissionGranted: true)))
    }
}
