import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel

    init(service: PetStateProviding) {
        _viewModel = StateObject(wrappedValue: StatsViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(title: "Building trends...")
                case .error(let message):
                    ErrorStateView(message: message, buttonTitle: "Retry") {
                        Task { await viewModel.load() }
                    }
                case .loaded(let snapshot):
                    ScrollView {
                        VStack(spacing: Spacing.medium) {
                            HStack(spacing: Spacing.small) {
                                UsageSummaryCardView(title: "Today", value: "\(snapshot.todayMinutes)m")
                                UsageSummaryCardView(title: "Weekly avg", value: "\(snapshot.weeklyAverageMinutes)m")
                            }

                            TrendPlaceholderChartView(trend: snapshot.trend)

                            categorySection(snapshot.categoryBreakdown)
                        }
                        .padding(Spacing.medium)
                    }
                    .refreshable {
                        await viewModel.load()
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
            .navigationTitle("Stats")
        }
        .task {
            await viewModel.load()
        }
    }

    private func categorySection(_ categories: [CategoryUsage]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Category Breakdown")
                .font(AppTypography.subtitle)

            ForEach(categories) { category in
                HStack {
                    Text(category.name)
                    Spacer()
                    Text("\(category.minutes)m")
                        .foregroundStyle(.secondary)
                }
                .font(AppTypography.body)
                .padding(.vertical, 4)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

#Preview {
    PreviewContainer {
        StatsView(service: MockPetStateService(settings: SettingsState(isOnboardingCompleted: true, notificationsEnabled: true, permissionGranted: true)))
    }
}
