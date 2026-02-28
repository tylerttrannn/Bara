import SwiftUI

struct PetHeroCardView: View {
    let mood: MoodState
    let description: String

    @State private var bob = false

    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: mood.symbolName)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(mood.tint)
                .offset(y: bob ? -4 : 4)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: bob)
                .onAppear { bob = true }

            Text(mood.title)
                .font(AppTypography.subtitle)

            Text(description)
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
}

#Preview {
    PreviewContainer {
        PetHeroCardView(mood: .neutral, description: "Capy is okay, but could use a calmer day.")
            .padding()
    }
}
