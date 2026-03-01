import SwiftUI

struct HPProgressCardView: View {
    let hp: Double
    let showPenaltyEmphasis: Bool
    let penaltyAmount: Int

    @State private var animatedHP: Double = 0
    @State private var penaltyBorderOpacity: Double = 0
    @State private var warningOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var shakeOffset: CGFloat = 0
    @State private var animationTask: Task<Void, Never>?

    init(
        hp: Double,
        showPenaltyEmphasis: Bool = false,
        penaltyAmount: Int = 0
    ) {
        self.hp = hp
        self.showPenaltyEmphasis = showPenaltyEmphasis
        self.penaltyAmount = penaltyAmount
    }

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

            if penaltyAmount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "heart.slash.fill")
                    Text("Health -\(penaltyAmount)")
                }
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(.red)
                .opacity(warningOpacity)
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
        .scaleEffect(pulseScale)
        .offset(x: shakeOffset)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(0.85), lineWidth: 2)
                .opacity(penaltyBorderOpacity)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onChange(of: showPenaltyEmphasis) { _, isActive in
            guard isActive else { return }
            runPenaltyAnimation()
        }
    }

    private func runPenaltyAnimation() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.15)) {
                penaltyBorderOpacity = 1
                warningOpacity = 1
                pulseScale = 1.02
            }

            withAnimation(.easeInOut(duration: 0.09).repeatCount(5, autoreverses: true)) {
                shakeOffset = 6
            }

            try? await Task.sleep(for: .milliseconds(520))

            withAnimation(.spring(duration: 0.35)) {
                shakeOffset = 0
                pulseScale = 1
            }

            try? await Task.sleep(for: .milliseconds(680))

            withAnimation(.easeOut(duration: 0.22)) {
                penaltyBorderOpacity = 0
                warningOpacity = 0
            }
        }
    }
}
