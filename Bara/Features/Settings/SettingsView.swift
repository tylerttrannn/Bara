import SwiftUI
import FamilyControls
import Toasts

struct SettingsView: View {
    private enum DefaultsKey {
        static let appGroupSuite = AppGroupDefaults.suiteName
        static let thresholdMinutes = AppGroupDefaults.thresholdMinutes
    }

    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.presentToast) private var presentToast
    let onResetDemo: () -> Void
    @State private var activitySelection = AppSelectionModel.getSelection()
    @State private var activitySelectionBeforeEditData: Data?
    @State private var isPickerPresented = false
    @State private var showThresholdEditor = false
    @State private var showUnpairConfirmation = false
    @State private var showResetConfirmation = false
    @State private var thresholdMinutes: Int = {
        let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
        let value = defaults.integer(forKey: DefaultsKey.thresholdMinutes)
        return value > 0 ? value : 30
    }()

    init(
        service: PetStateProviding,
        buddyService: BuddyProviding = BuddyServiceFactory.makeDefault(),
        allowanceStore: BorrowAllowanceProviding = AppGroupBorrowAllowanceStore(),
        onResetDemo: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                service: service,
                buddyService: buddyService,
                allowanceStore: allowanceStore
            )
        )
        self.onResetDemo = onResetDemo
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    SettingRowView(title: "Edit Distractions", subtitle: "Open app/category selector") {
                        settingsActionButton("Edit") {
                            Haptics.impact(.light)
                            activitySelectionBeforeEditData = encodedSelection(activitySelection)
                            isPickerPresented = true
                        }
                    }

                    SettingRowView(title: "Threshold Time", subtitle: "Current: \(thresholdMinutes) min") {
                        settingsActionButton("Change") {
                            Haptics.impact(.light)
                            loadThresholdFromDefaults()
                            showThresholdEditor = true
                        }
                    }

                    if viewModel.buddyProfile?.isPaired == true {
                        Text("Buddy")
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, Spacing.small)

                        SettingRowView(
                            title: "Unpair Buddy",
                            subtitle: "Unlink both users and expire pending requests."
                        ) {
                            settingsActionButton(
                                "Unpair",
                                tint: Color.red.opacity(0.85),
                                isDisabled: viewModel.unpairState.isLoading
                            ) {
                                Haptics.impact(.light)
                                showUnpairConfirmation = true
                            }
                        }
                    }

                    Text("Demo")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Spacing.small)

                    SettingRowView(title: "Block Apps Instantly", subtitle: "Runs the same start activity flow") {
                        settingsActionButton("Block") {
                            Haptics.impact(.medium)
                            viewModel.triggerBlockNow()
                            presentToast(ToastFactory.make(kind: .info, message: "Block test triggered."))
                        }
                    }

                    SettingRowView(title: "Unblock Apps Instantly", subtitle: "Clears shields once for demo testing") {
                        settingsActionButton("Unblock") {
                            Haptics.impact(.medium)
                            viewModel.triggerUnblockNow()
                            presentToast(ToastFactory.make(kind: .info, message: "Unblock test triggered."))
                        }
                    }

                    SettingRowView(title: "Reset Demo State", subtitle: "Server + local reset, then onboarding.") {
                        settingsActionButton("Reset", isDisabled: viewModel.resetState.isLoading) {
                            Haptics.impact(.medium)
                            showResetConfirmation = true
                        }
                    }
                }
                .padding(Spacing.medium)
            }
            .background(
                LinearGradient(
                    colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
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
            .onChange(of: isPickerPresented) { _, isPresented in
                guard !isPresented else { return }

                let before = activitySelectionBeforeEditData
                let after = encodedSelection(activitySelection)
                activitySelectionBeforeEditData = nil

                if before != nil, before != after {
                    Haptics.notify(.success)
                    presentToast(ToastFactory.make(kind: .success, message: "Distraction selection saved."))
                }
            }
            .sheet(isPresented: $showThresholdEditor) {
                ThresholdEditorSheet(
                    thresholdMinutes: $thresholdMinutes,
                    onSave: { savedMinutes in
                        saveThresholdToDefaults(savedMinutes)
                        Haptics.notify(.success)
                        presentToast(ToastFactory.make(kind: .success, message: "Threshold saved: \(savedMinutes) min."))
                    }
                )
            }
            .onAppear {
                loadThresholdFromDefaults()
            }
        }
        .addToastSafeAreaObserver()
        .task {
            await viewModel.loadBuddyProfile()
        }
        .onChange(of: viewModel.unpairState) { _, newState in
            switch newState {
            case .success:
                Haptics.notify(.success)
                presentToast(ToastFactory.make(kind: .success, message: "Unpaired. You can now pair with someone else."))
            case .error(let message):
                Haptics.notify(.error)
                presentToast(ToastFactory.make(kind: .error, message: message))
            case .idle, .loading:
                break
            }
        }
        .onChange(of: viewModel.resetState) { _, newState in
            switch newState {
            case .success:
                Haptics.notify(.success)
                presentToast(ToastFactory.make(kind: .success, message: "Demo reset complete."))
                onResetDemo()
            case .error(let message):
                Haptics.notify(.error)
                presentToast(ToastFactory.make(kind: .error, message: message))
            case .idle, .loading:
                break
            }
        }
        .confirmationDialog(
            "Unpair buddy?",
            isPresented: $showUnpairConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unpair Buddy", role: .destructive) {
                Haptics.impact(.medium)
                Task { await viewModel.unpairBuddy() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will unlink both users and expire pending buddy requests.")
        }
        .confirmationDialog(
            "Reset demo state?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                Haptics.impact(.medium)
                Task { await viewModel.resetDemoState() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears pairing, points, health, threshold, app selections, and returns to onboarding.")
        }
    }

    private func loadThresholdFromDefaults() {
        let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
        let value = defaults.integer(forKey: DefaultsKey.thresholdMinutes)
        thresholdMinutes = value > 0 ? value : 30
    }

    private func saveThresholdToDefaults(_ value: Int) {
        let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
        defaults.set(value, forKey: DefaultsKey.thresholdMinutes)
    }

    private func encodedSelection(_ selection: FamilyActivitySelection) -> Data? {
        try? JSONEncoder().encode(selection)
    }

    private func settingsActionButton(
        _ title: String,
        tint: Color = AppColors.accentGreen,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption.weight(.semibold))
                .frame(width: 72, height: 26)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .disabled(isDisabled)
    }
}

private struct ThresholdEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var thresholdMinutes: Int
    let onSave: (Int) -> Void
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
                        Haptics.impact(.light)
                        onSave(thresholdMinutes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onChange(of: thresholdMinutes) { _, _ in
            Haptics.selection()
        }
    }
}
