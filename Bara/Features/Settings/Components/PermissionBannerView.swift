import SwiftUI

struct PermissionBannerView: View {
    let granted: Bool

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: granted ? "checkmark.shield.fill" : "shield.lefthalf.filled.slash")
                .foregroundStyle(granted ? AppColors.accentGreen : AppColors.moodDistressed)

            Text(granted ? "Permission placeholder: Ready for Screen Time integration." : "Permission placeholder: Not granted.")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

