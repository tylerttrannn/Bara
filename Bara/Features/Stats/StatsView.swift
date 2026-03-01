import SwiftUI
import DeviceActivity
import _DeviceActivity_SwiftUI
import Toasts

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel
    @State private var showReportSplash = true
    @State private var splashTask: Task<Void, Never>?
    @Environment(\.presentToast) private var presentToast

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
                case .loaded:
                    ScrollView {
                        VStack(spacing: Spacing.medium) {
                            HStack(spacing: Spacing.small) {
                                DeviceActivityReport(.statsTodayCard, filter: todayActivityFilter)
                                    .frame(height: 84)
                                    .allowsHitTesting(false)

                                DeviceActivityReport(.statsWeeklyAverageCard, filter: weeklyActivityFilter)
                                    .frame(height: 84)
                                    .allowsHitTesting(false)
                            }

                            VStack(spacing: Spacing.medium) {
                                DeviceActivityReport(.statsWeeklyTrendChart, filter: weeklyActivityFilter)
                                    .frame(height: 236, alignment: .top)
                                    .allowsHitTesting(false)

                                DeviceActivityReport(.statsMoodCalendar, filter: moodCalendarActivityFilter)
                                    .frame(height: 200, alignment: .top)
                                    .allowsHitTesting(true)
                            }

                            DeviceActivityReport(.statsTopApps, filter: weeklyActivityFilter)
                                .frame(height: 220, alignment: .top)
                                .allowsHitTesting(false)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(Spacing.medium)
                    }
                    .overlay {
                        if showReportSplash {
                            StatsLoadingSplashOverlayView()
                                .transition(.opacity)
                        }
                    }
                    .onAppear {
                        showStatsSplash()
                    }
                    .onDisappear {
                        splashTask?.cancel()
                    }
                    .refreshable {
                        showStatsSplash()
                        await viewModel.load()
                        switch viewModel.state {
                        case .error(let message):
                            presentToast(ToastFactory.make(kind: .error, message: message))
                        case .loaded:
                            presentToast(ToastFactory.make(kind: .success, message: "Stats updated."))
                        case .idle, .loading:
                            break
                        }
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
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)

        }
        .addToastSafeAreaObserver()
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

    private func showStatsSplash() {
        splashTask?.cancel()
        showReportSplash = true

        splashTask = Task {
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showReportSplash = false
                }
            }
        }
    }
}


private struct StatsLoadingSplashOverlayView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.medium) {
                Image("very_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
                    .scaleEffect(animate ? 1.03 : 0.97)
                    .offset(y: animate ? -4 : 4)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animate)

                Text("Loading your stats...")
                    .font(AppTypography.subtitle)

                ProgressView()
                    .tint(AppColors.accentTeal)
            }
            .padding(.horizontal, Spacing.large)
        }
        .allowsHitTesting(true)
        .onAppear { animate = true }
    }
}
