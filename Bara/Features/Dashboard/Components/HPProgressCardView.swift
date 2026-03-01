import SwiftUI

struct HPProgressCardView: View {
    let hp: Double

    @State private var animatedHP: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Health")
                    .font(AppTypography.subtitle)
                Spacer()
                Text("\(Int(animatedHP.rounded()))/100")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(AppColors.accentGreen)
            }

            ProgressView(value: animatedHP, total: 100)
                .tint(AppColors.accentGreen)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                .onAppear {
                    withAnimation(.spring(duration: 0.8)) {
                        animatedHP = hp
                    }
                }
                .onChange(of: hp) { _, newValue in
                    withAnimation(.spring(duration: 0.6)) {
                        animatedHP = newValue
                    }
                }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

