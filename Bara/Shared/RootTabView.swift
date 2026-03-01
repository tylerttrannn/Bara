import SwiftUI

struct RootTabView: View {
    private let service: PetStateProviding

    @State private var showOnboarding: Bool

    init(service: PetStateProviding) {
        self.service = service
        _showOnboarding = State(initialValue: !service.fetchSettingsState().isOnboardingCompleted)
    }

    var body: some View {
        TabView {
            DashboardView(service: service)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .accessibilityIdentifier("tab.dashboard")

            StatsView(service: service)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .accessibilityIdentifier("tab.stats")

            SettingsView(service: service, onResetDemo: {
                showOnboarding = true
            })
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
