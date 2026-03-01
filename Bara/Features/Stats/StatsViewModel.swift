import Foundation
import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    @Published private(set) var state: ViewState<UsageSnapshot> = .idle

    private let service: PetStateProviding

    init(service: PetStateProviding) {
        self.service = service
    }

    func load() async {
        state = .loading

        do {
            let snapshot = try await service.fetchStatsSnapshot()
            state = .loaded(snapshot)
        } catch {
            state = .error(ToastFactory.userMessage(from: error))
        }
    }
}
