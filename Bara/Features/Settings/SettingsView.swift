import SwiftUI
import FamilyControls

struct SettingsView: View {
    private enum DefaultsKey {
        static let appGroupSuite = "group.com.Bara.appblocker"
        static let thresholdMinutes = "bara.threshold.minutes"
    }

    @StateObject private var viewModel: SettingsViewModel
    let onResetDemo: () -> Void
    @State private var activitySelection = AppSelectionModel.getSelection()
    @State private var isPickerPresented = false
    @State private var showThresholdEditor = false
    @State private var thresholdMinutes: Int = {
        let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
        let value = defaults.integer(forKey: DefaultsKey.thresholdMinutes)
        return value > 0 ? value : 30
    }()

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

                    SettingRowView(title: "Edit Distractions", subtitle: "Open app/category selector") {
                        Button("Edit") {
                            isPickerPresented = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accentTeal)
                    }

                    SettingRowView(title: "Threshold Time", subtitle: "Current: \(thresholdMinutes) min") {
                        Button("Change") {
                            loadThresholdFromDefaults()
                            showThresholdEditor = true
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.accentGreen)
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
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $activitySelection
            )
            .onChange(of: activitySelection) { _, newSelection in
                AppSelectionModel.setSelection(newSelection)
            }
            .sheet(isPresented: $showThresholdEditor) {
                ThresholdEditorSheet(
                    thresholdMinutes: $thresholdMinutes,
                    onSave: {
                        saveThresholdToDefaults()
                    }
                )
            }
            .onAppear {
                loadThresholdFromDefaults()
            }
        }
    }

    private func loadThresholdFromDefaults() {
        let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
        let value = defaults.integer(forKey: DefaultsKey.thresholdMinutes)
        thresholdMinutes = value > 0 ? value : 30
    }

    private func saveThresholdToDefaults() {
        let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
        defaults.set(thresholdMinutes, forKey: DefaultsKey.thresholdMinutes)
    }
}

private struct ThresholdEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var thresholdMinutes: Int
    let onSave: () -> Void
    private let quickPicks = [15, 30, 45, 60]

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.large) {
                VStack(spacing: Spacing.small) {
                    Text("Threshold Time")
                        .font(AppTypography.title)
                    Text("Adjust how long distracting usage can run before limits trigger.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("\(thresholdMinutes) min")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.accentGreen)

                Stepper("Adjust in 5-minute steps", value: $thresholdMinutes, in: 5...180, step: 5)
                    .font(AppTypography.body)
                    .padding()
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 10) {
                    ForEach(quickPicks, id: \.self) { minutes in
                        Button("\(minutes)m") {
                            thresholdMinutes = minutes
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(thresholdMinutes == minutes ? AppColors.accentGreen : AppColors.accentTeal.opacity(0.55))
                    }
                }

                Spacer()
            }
            .padding(Spacing.large)
            .navigationTitle("Change Threshold")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

