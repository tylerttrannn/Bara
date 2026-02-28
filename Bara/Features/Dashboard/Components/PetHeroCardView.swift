import SwiftUI

struct PetHeroCardView: View {
    let mood: MoodState
    let description: String

    @State private var bob = false

    var body: some View {
        VStack(spacing: Spacing.small) {
            moodVisual
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
    }

    @ViewBuilder
    private var moodVisual: some View {
        if mood == .happy, UIImage(named: "very_happy") != nil {
            Image("very_happy")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
        } else if mood == .neutral, UIImage(named: "neutral") != nil {
            Image("neutral")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
        } else {
            Image(systemName: mood.symbolName)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(mood.tint)
        }
    }
}

#Preview {
    PreviewContainer {
        PetHeroCardView(mood: .neutral, description: "Capy is okay, but could use a calmer day.")
            .padding()
    }
}
