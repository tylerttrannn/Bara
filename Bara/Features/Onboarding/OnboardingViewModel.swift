import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    struct Step: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let symbolName: String
    }

    @Published var pageIndex = 0

    let steps: [Step] = [
        Step(
            title: "Meet Bara",
            detail: "Bara mirrors your focus. Tap below to choose distracting apps and set your threshold.",
            symbolName: "pawprint.fill"
        )
    ]

    var isLastPage: Bool {
        pageIndex == steps.count - 1
    }

    func advance() {
        guard pageIndex < steps.count - 1 else { return }
        pageIndex += 1
    }

    func goBack() {
        guard pageIndex > 0 else { return }
        pageIndex -= 1
    }
}
