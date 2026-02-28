import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onFinish: () -> Void

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
