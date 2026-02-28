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
            detail: "Your capybara reflects your focus. Keep distracting time low to keep Bara happy.",
            symbolName: "pawprint.fill"
        ),
        Step(
            title: "Pick Distractions",
            detail: "Swipe here, choose distracting apps, then set your punishment threshold.",
            symbolName: "square.stack.3d.up.fill"
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
