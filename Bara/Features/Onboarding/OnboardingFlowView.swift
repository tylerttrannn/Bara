import SwiftUI
import FamilyControls

struct OnboardingFlowView: View {
    private enum DefaultsKey {
        static let appGroupSuite = "group.com.Bara.appblocker"
        static let thresholdMinutes = "bara.threshold.minutes"
    }

    @StateObject private var viewModel = OnboardingViewModel()
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
                colors: [AppColors.sandBackground, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.large) {
                TabView(selection: $viewModel.pageIndex) {
                    ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                        VStack(spacing: Spacing.large) {
                            Spacer()

                            Image("very_happy")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)

                            Text(step.title)
                                .font(AppTypography.title)

                            Text(step.detail)
                                .font(AppTypography.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Spacing.large)

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots

                Button("Select distracting apps") {
                    showScreenTimePermissionInfo = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentTeal)
                .opacity(viewModel.pageIndex == 1 ? 1 : 0)
                .disabled(viewModel.pageIndex != 1)
                .frame(height: 44)

                Button("Skip") {
                    onFinish()
                }
                .font(AppTypography.caption)
                .padding(.top, Spacing.xSmall)
            }
            .padding(Spacing.large)
        }
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $activitySelection
        )
        .onChange(of: activitySelection) { _, newSelection in
            if !newSelection.applicationTokens.isEmpty || !newSelection.categoryTokens.isEmpty || !newSelection.webDomainTokens.isEmpty {
                AppSelectionModel.setSelection(activitySelection)
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
                    showThresholdPage = false
                    onFinish()
                }
            )
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.steps.indices, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.pageIndex ? AppColors.accentGreen : Color.gray.opacity(0.35))
                    .frame(width: index == viewModel.pageIndex ? 12 : 8, height: index == viewModel.pageIndex ? 12 : 8)
            }
        }
    }
}


private struct ScreenTimePermissionInfoView: View {
    let onBack: () -> Void
    let onContinue: () -> Void
    @StateObject var authManager = AuthorizationManager()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppColors.sandBackground, Color.white],
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
                            Text("Authorization Granted")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.accentGreen)
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

                    if authManager.authorizationStatus == .approved {
                        Button("Continue") {
                            onContinue()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accentGreen)
                        .font(AppTypography.body)
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Request Authorization") {
                            Task {
                                await authManager.requestAuthorization()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accentTeal)
                        .font(AppTypography.body)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(Spacing.large)
            }
            .task {
                await authManager.checkAuthorization()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        onBack()
                    }
                }
            }
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
                    colors: [AppColors.sandBackground, Color.white],
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

                        Text("Set Punishment Threshold")
                            .font(AppTypography.title)
                            .multilineTextAlignment(.center)

                        Text("How long can distracting usage go before Bara starts taking damage?")
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

                    Button("Start Dashboard") {
                        onContinue()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accentGreen)
                    .font(AppTypography.body)
                    .frame(maxWidth: .infinity)
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
    }
}

