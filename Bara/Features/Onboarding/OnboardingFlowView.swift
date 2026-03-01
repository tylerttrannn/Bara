import SwiftUI
import FamilyControls
import Toasts

struct OnboardingFlowView: View {
    private enum DefaultsKey {
        static let appGroupSuite = AppGroupDefaults.suiteName
        static let thresholdMinutes = AppGroupDefaults.thresholdMinutes
    }

    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.presentToast) private var presentToast
    let onFinish: () -> Void
    let onRequestScreenTimePermission: () -> Void
    @State private var activitySelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var showScreenTimePermissionInfo = false
    @State private var showThresholdPage = false
    @State private var thresholdMinutes = 30

    
    init(
        onFinish: @escaping () -> Void,
        onRequestScreenTimePermission: @escaping () -> Void = {}
    ) {
        self.onFinish = onFinish
        self.onRequestScreenTimePermission = onRequestScreenTimePermission
        let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
        let savedThreshold = defaults.integer(forKey: DefaultsKey.thresholdMinutes)
        _thresholdMinutes = State(initialValue: savedThreshold > 0 ? savedThreshold : 30)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.large) {
                Spacer()

                Image("very_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)

                Text(viewModel.steps.first?.title ?? "Meet Bara")
                    .font(AppTypography.title)

                Text(viewModel.steps.first?.detail ?? "Bara mirrors your focus.")
                    .font(AppTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.large)

                Spacer()

                Button {
                    Haptics.impact(.light)
                    showScreenTimePermissionInfo = true
                } label: {
                    Text("Select Apps")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentGreen)
                .font(AppTypography.body)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.xSmall)
            }
            .padding(Spacing.large)
        }
        .addToastSafeAreaObserver()
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $activitySelection
        )
        .onChange(of: activitySelection) { _, newSelection in
            if !newSelection.applicationTokens.isEmpty || !newSelection.categoryTokens.isEmpty || !newSelection.webDomainTokens.isEmpty {
                AppSelectionModel.setSelection(activitySelection)
                Haptics.notify(.success)
                presentToast(ToastFactory.make(kind: .success, message: "Distractions saved."))
                showThresholdPage = true
            }
        }
        .fullScreenCover(isPresented: $showScreenTimePermissionInfo) {
            ScreenTimePermissionInfoView(
                onBack: { showScreenTimePermissionInfo = false },
                onContinue: {
                    onRequestScreenTimePermission()
                    showScreenTimePermissionInfo = false
                    isPickerPresented = true
                }
            )
        }
        .fullScreenCover(isPresented: $showThresholdPage) {
            ThresholdSelectionView(
                thresholdMinutes: $thresholdMinutes,
                onCancel: { showThresholdPage = false },
                onContinue: {
                    let defaults = UserDefaults(suiteName: DefaultsKey.appGroupSuite) ?? .standard
                    defaults.set(thresholdMinutes, forKey: DefaultsKey.thresholdMinutes)
                    Haptics.notify(.success)
                    presentToast(ToastFactory.make(kind: .success, message: "Threshold set to \(thresholdMinutes) min."))
                    showThresholdPage = false
                    onFinish()
                }
            )
        }
    }
}


private struct ScreenTimePermissionInfoView: View {
    let onBack: () -> Void
    let onContinue: () -> Void
    @StateObject var authManager = AuthorizationManager()
    @Environment(\.presentToast) private var presentToast
    @State private var hasAutoContinued = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: Spacing.large) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 82, height: 82)
                            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)

                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(AppColors.accentTeal)
                    }

                    Text("Screen Time Access Needed")
                        .font(AppTypography.title)
                        .multilineTextAlignment(.center)

                    Text("To track distracting apps, you need to allow Screen Time access on the next prompt.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.large)

                    Group {
                        switch authManager.authorizationStatus {
                        case .approved:
                            VStack(spacing: 8) {
                                Text("Authorization Granted")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.accentGreen)
                                Text("Opening app selector...")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                                ProgressView()
                                    .tint(AppColors.accentGreen)
                            }
                        case .denied:
                            Text("Authorization denied. You can enable it in Settings and come back.")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        case .notDetermined:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, Spacing.large)

                    Spacer()

                    if authManager.authorizationStatus != .approved {
                        Button {
                            Haptics.impact(.medium)
                            Task {
                                await authManager.requestAuthorization()
                            }
                        } label: {
                            Text("Request Authorization")
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accentGreen)
                        .font(AppTypography.body)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xSmall)
                    }
                }
                .padding(Spacing.large)
            }
            .task {
                await authManager.checkAuthorization()
                if authManager.authorizationStatus == .approved {
                    autoContinueIfNeeded()
                }
            }
            .onChange(of: authManager.authorizationStatus) { _, newStatus in
                switch newStatus {
                case .approved:
                    Haptics.notify(.success)
                    presentToast(ToastFactory.make(kind: .success, message: "Screen Time access granted."))
                    autoContinueIfNeeded()
                case .denied:
                    Haptics.notify(.error)
                    presentToast(ToastFactory.make(kind: .error, message: "Screen Time access denied. Enable it in Settings."))
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        Haptics.impact(.light)
                        onBack()
                    }
                }
            }
        }
    }

    private func autoContinueIfNeeded() {
        guard !hasAutoContinued else { return }
        hasAutoContinued = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onContinue()
        }
    }
}

private struct ThresholdSelectionView: View {
    @Binding var thresholdMinutes: Int
    let onCancel: () -> Void
    let onContinue: () -> Void
    private let quickPicks = [15, 30, 45, 60]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: Spacing.large) {
                    VStack(spacing: Spacing.small) {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 78, height: 78)
                                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)

                            Image(systemName: "timer")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(AppColors.accentTeal)
                        }

                        Text("Set App Threshold")
                            .font(AppTypography.title)
                            .multilineTextAlignment(.center)

                        Text("Set how many minutes are allowed before selected apps are blocked.")
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.small)
                    }

                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text("Current threshold")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(thresholdMinutes)")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.accentGreen)
                            Text("min")
                                .font(AppTypography.subtitle)
                                .foregroundStyle(.secondary)
                        }

                        Stepper("Adjust in 5-minute steps", value: $thresholdMinutes, in: 5...180, step: 5)
                            .font(AppTypography.body)

                        HStack(spacing: 10) {
                            ForEach(quickPicks, id: \.self) { minutes in
                                Button("\(minutes)m") {
                                    thresholdMinutes = minutes
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(thresholdMinutes == minutes ? AppColors.accentGreen : AppColors.accentTeal.opacity(0.55))
                            }
                        }
                    }
                    .padding(Spacing.large)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 5)

                    Spacer(minLength: 0)

                    Button {
                        Haptics.impact(.medium)
                        onContinue()
                    } label: {
                        Text("Finish Setup")
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accentGreen)
                    .font(AppTypography.body)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xSmall)
                }
                .padding(Spacing.large)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        onCancel()
                    }
                }
            }
        }
        .onChange(of: thresholdMinutes) { _, _ in
            Haptics.selection()
        }
    }
}
