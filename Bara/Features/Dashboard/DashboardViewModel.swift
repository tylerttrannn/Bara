import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state: ViewState<PetSnapshot> = .idle

    private let service: PetStateProviding

    init(service: PetStateProviding) {
        self.service = service
    }

    func load() async {
        guard case .idle = state else { return }
        await refresh()
    }

    func refresh() async {
        state = .loading

        do {
            let snapshot = try await service.fetchDashboardSnapshot()
            state = .loaded(snapshot)
        } catch {
            state = .error("Could not load capybara status right now.")
        }
    }
}
