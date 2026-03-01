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
        if let assetName = moodAssetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
        } else {
            Image(systemName: mood.symbolName)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(mood.tint)
        }
    }

    private var moodAssetName: String? {
        let candidates: [String]

        switch mood {
        case .happy:
            candidates = ["very_happy", "happy"]
        case .neutral:
            candidates = ["neutral"]
        case .sad:
            candidates = ["sad"]
        case .distressed:
            candidates = ["sad", "distressed"]
        }

        return candidates.first(where: { UIImage(named: $0) != nil })
    }
}
