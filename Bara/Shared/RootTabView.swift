import SwiftUI

struct RootTabView: View {
    private let service: PetStateProviding
    private let buddyService: BuddyProviding
    private let allowanceStore: BorrowAllowanceProviding

    @State private var showOnboarding: Bool

    init(
        service: PetStateProviding,
        buddyService: BuddyProviding = BuddyServiceFactory.makeDefault(),
        allowanceStore: BorrowAllowanceProviding = AppGroupBorrowAllowanceStore()
    ) {
        self.service = service
        self.buddyService = buddyService
        self.allowanceStore = allowanceStore
        _showOnboarding = State(initialValue: !service.fetchSettingsState().isOnboardingCompleted)
    }

    var body: some View {
        TabView {
            DashboardView(service: service, buddyService: buddyService, allowanceStore: allowanceStore)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .accessibilityIdentifier("tab.dashboard")

            StatsView(service: service)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .accessibilityIdentifier("tab.stats")

            SettingsView(
                service: service,
                buddyService: buddyService,
                allowanceStore: allowanceStore,
                onResetDemo: {
                    showOnboarding = true
                }
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .accessibilityIdentifier("tab.settings")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView {
                service.setOnboardingCompleted(true)
                showOnboarding = false
            }
        }
    }
}
