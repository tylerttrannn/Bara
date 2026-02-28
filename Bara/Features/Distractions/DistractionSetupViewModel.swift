import Foundation
import Combine

@MainActor
final class DistractionSetupViewModel: ObservableObject {
    @Published var preferences: DistractionPreferences

    let availableApps: [DistractingAppOption] = [
        DistractingAppOption(id: "instagram", name: "Instagram", symbolName: "camera.circle"),
        DistractingAppOption(id: "tiktok", name: "TikTok", symbolName: "music.note.tv"),
        DistractingAppOption(id: "youtube", name: "YouTube", symbolName: "play.rectangle"),
        DistractingAppOption(id: "x", name: "X", symbolName: "text.bubble"),
        DistractingAppOption(id: "reddit", name: "Reddit", symbolName: "ellipsis.bubble"),
        DistractingAppOption(id: "games", name: "Mobile Games", symbolName: "gamecontroller")
    ]

    private let service: PetStateProviding

    init(service: PetStateProviding) {
        self.service = service
        self.preferences = service.fetchDistractionPreferences()
    }

    func toggleSelection(for appID: String) {
        if preferences.selectedAppIDs.contains(appID) {
            preferences.selectedAppIDs.remove(appID)
        } else {
            preferences.selectedAppIDs.insert(appID)
        }
    }

    func save() {
        service.saveDistractionPreferences(preferences)
    }

    func isSelected(_ appID: String) -> Bool {
        preferences.selectedAppIDs.contains(appID)
    }
}
