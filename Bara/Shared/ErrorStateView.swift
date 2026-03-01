import SwiftUI

struct ErrorStateView: View {
    let message: String
    let buttonTitle: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppColors.moodDistressed)
            Text(message)
                .font(AppTypography.body)
                .multilineTextAlignment(.center)
            Button(buttonTitle, action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentGreen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.large)
    }
}
