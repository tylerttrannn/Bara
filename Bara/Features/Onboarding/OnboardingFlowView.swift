import SwiftUI
import FamilyControls

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onFinish: () -> Void
    let onPickDistractions: () -> Void
    @State private var activitySelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var showThresholdPage = false
    @State private var thresholdMinutes = 30

    
    init(onFinish: @escaping () -> Void, onPickDistractions: @escaping () -> Void = {}) {
        self.onFinish = onFinish
        self.onPickDistractions = onPickDistractions
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
                    isPickerPresented = true
                }
                .familyActivityPicker(
                    isPresented: $isPickerPresented,
                    selection: $activitySelection
                )
                .onChange(of: activitySelection) { _, newSelection in
                    if !newSelection.applicationTokens.isEmpty || !newSelection.categoryTokens.isEmpty || !newSelection.webDomainTokens.isEmpty {
                        onPickDistractions()
                        showThresholdPage = true
                    }
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
        .fullScreenCover(isPresented: $showThresholdPage) {
            ThresholdSelectionView(
                thresholdMinutes: $thresholdMinutes,
                onCancel: { showThresholdPage = false },
                onContinue: {
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

#Preview {
    OnboardingFlowView(onFinish: {})
}
