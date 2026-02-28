import SwiftUI
import DeviceActivity
import _DeviceActivity_SwiftUI

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
                                DeviceActivityReport(.statsTodayCard, filter: todayActivityFilter)
                                    .frame(height: 84)

                                DeviceActivityReport(.statsWeeklyAverageCard, filter: weeklyActivityFilter)
                                    .frame(height: 84)
                            }

                            VStack(spacing: Spacing.xSmall) {
                                DeviceActivityReport(.statsWeeklyTrendChart, filter: weeklyActivityFilter)
                                    .frame(height: 210, alignment: .top)

                                DeviceActivityReport(.statsMoodCalendar, filter: moodCalendarActivityFilter)
                                    .frame(height: 200, alignment: .top)
                            }

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
            .navigationBarTitleDisplayMode(.inline)

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

        return DeviceActivityFilter(segment: .daily(during: dayInterval))
    }

    private var weeklyActivityFilter: DeviceActivityFilter {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfRange = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
        let weekInterval = DateInterval(start: startOfRange, end: endOfToday)

        return DeviceActivityFilter(segment: .daily(during: weekInterval))
    }

    private var moodCalendarActivityFilter: DeviceActivityFilter {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let latestWeekStart = calendar.dateInterval(of: .weekOfYear, for: todayStart)?.start ?? todayStart
        let oldestWeekStart = calendar.date(byAdding: .weekOfYear, value: -11, to: latestWeekStart) ?? latestWeekStart
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        let interval = DateInterval(start: oldestWeekStart, end: endOfToday)

        return DeviceActivityFilter(segment: .daily(during: interval))
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
