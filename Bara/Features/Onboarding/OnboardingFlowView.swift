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

                    Image(systemName: "timer")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(AppColors.accentTeal)

                    Text("Set Punishment Threshold")
                        .font(AppTypography.title)
                        .multilineTextAlignment(.center)

                    Text("Choose how many minutes of distracting usage before Bara starts taking damage.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.large)

                    Text("\(thresholdMinutes) minutes")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.accentGreen)

                    Stepper("Threshold", value: $thresholdMinutes, in: 5...180, step: 5)
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, Spacing.large)

                    Spacer()

                    Button("Start Dashboard") {
                        onContinue()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accentGreen)
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
