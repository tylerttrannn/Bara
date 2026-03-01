import SwiftUI

struct QuickActionsRowView: View {
    let onEditDistractions: () -> Void
    let onPetCare: () -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            Button("Edit distractions", action: onEditDistractions)
                .buttonStyle(.bordered)
                .tint(AppColors.accentTeal)

            Button("Pet care", action: onPetCare)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentGreen)
        }
        .font(AppTypography.body)
    }
}

