import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    let onResetDemo: () -> Void

    init(service: PetStateProviding, onResetDemo: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(service: service))
        self.onResetDemo = onResetDemo
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    PermissionBannerView(granted: viewModel.settings.permissionGranted)

                    SettingRowView(title: "Notifications", subtitle: "Mock local reminder toggle") {
                        Toggle("Notifications", isOn: Binding(
                            get: { viewModel.settings.notificationsEnabled },
                            set: { viewModel.setNotifications($0) }
                        ))
                        .labelsHidden()
                    }

                    SettingRowView(title: "Reset Demo State", subtitle: "Show onboarding again") {
                        Button("Reset") {
                            viewModel.completeOnboarding(false)
                            onResetDemo()
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.accentTeal)
                    }

                    SettingRowView(title: "Blocking Test", subtitle: "Start DeviceActivity monitoring now") {
                        Button("Start test") {
                            viewModel.startActivityLimitTest()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accentGreen)
                    }

                    SettingRowView(title: "About Bara", subtitle: "Hackathon MVP UI shell") {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AppColors.accentTeal)
                    }
                }
                .padding(Spacing.medium)
            }
            .background(
                LinearGradient(
                    colors: [AppColors.sandBackground, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)

        }
    }
}

#Preview {
    PreviewContainer {
        SettingsView(
            service: MockPetStateService(settings: SettingsState(isOnboardingCompleted: true, notificationsEnabled: true, permissionGranted: true)),
            onResetDemo: {}
        )
    }
}
