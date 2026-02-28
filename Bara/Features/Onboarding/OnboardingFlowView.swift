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
                Spacer()

                let step = viewModel.steps[viewModel.pageIndex]
                Image(systemName: step.symbolName)
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(AppColors.accentTeal)
                    .padding(Spacing.medium)
                    .background(AppColors.cardBackground)
                    .clipShape(Circle())

                Text(step.title)
                    .font(AppTypography.title)

                Text(step.detail)
                    .font(AppTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.large)

                pageDots

                Spacer()

                HStack(spacing: Spacing.small) {
                    if viewModel.pageIndex > 0 {
                        Button("Back") {
                            viewModel.goBack()
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.accentTeal)
                    }

                    Button(viewModel.isLastPage ? "Get Started" : "Continue") {
                        if viewModel.isLastPage {
                            onFinish()
                        } else {
                            viewModel.advance()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accentGreen)
                }

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
