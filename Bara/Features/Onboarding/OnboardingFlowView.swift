import SwiftUI
import FamilyControls

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onFinish: () -> Void
    let onPickDistractions: () -> Void
    @State private var activitySelection = FamilyActivitySelection()
    @State private var isPickerPresented = false

    
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

                Button("Get Started") {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentGreen)
                .opacity(viewModel.isLastPage ? 1 : 0)
                .disabled(!viewModel.isLastPage)
                .frame(height: 44)

                Button("Select distracting apps") {
                    isPickerPresented = true
                }
                .familyActivityPicker(
                    isPresented: $isPickerPresented,
                    selection: $activitySelection
                )
                
                .onChange(of: activitySelection) { newSelection in
                    if !newSelection.applicationTokens.isEmpty || !newSelection.categoryTokens.isEmpty || !newSelection.webDomainTokens.isEmpty {
                        onPickDistractions() // should move pages from this poitn 
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

#Preview {
    OnboardingFlowView(onFinish: {})
}
