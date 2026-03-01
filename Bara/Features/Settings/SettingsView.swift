import SwiftUI
import FamilyControls

struct SettingsView: View {
    private enum DefaultsKey {
        static let appGroupSuite = AppGroupDefaults.suiteName
        static let thresholdMinutes = AppGroupDefaults.thresholdMinutes
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
                    SettingRowView(title: "Notifications", subtitle: "Mock local reminder toggle") {
                        Toggle("Notifications", isOn: Binding(
                            get: { viewModel.settings.notificationsEnabled },
                            set: { viewModel.setNotifications($0) }
                        ))
                        .labelsHidden()
                    }

                    SettingRowView(title: "Edit Distractions", subtitle: "Open app/category selector") {
                        settingsActionButton("Edit") {
                            isPickerPresented = true
                        }
                    }

                    SettingRowView(title: "Threshold Time", subtitle: "Current: \(thresholdMinutes) min") {
                        settingsActionButton("Change") {
                            loadThresholdFromDefaults()
                            showThresholdEditor = true
                        }
                    }

                    Text("Demo")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Spacing.small)

                    SettingRowView(title: "Block Apps Instantly", subtitle: "Runs the same start activity flow") {
                        settingsActionButton("Block") {
                            viewModel.triggerBlockNow()
                        }
                    }

                    SettingRowView(title: "Unblock Apps Instantly", subtitle: "Clears shields once for demo testing") {
                        settingsActionButton("Unblock") {
                            viewModel.triggerUnblockNow()
                        }
                    }

                    SettingRowView(title: "Reset Demo State", subtitle: "Clears local demo-only progress/state") {
                        settingsActionButton("Reset") {
                            onResetDemo()
                        }
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

    private func settingsActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption.weight(.semibold))
                .frame(width: 72, height: 26)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.accentGreen)
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
