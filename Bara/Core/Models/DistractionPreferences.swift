import Foundation

struct DistractingAppOption: Identifiable, Equatable {
    let id: String
    let name: String
    let symbolName: String
}

struct DistractionPreferences: Equatable {
    var selectedAppIDs: Set<String>
    var thresholdMinutes: Int

    static let `default` = DistractionPreferences(
        selectedAppIDs: ["instagram", "youtube"],
        thresholdMinutes: 30
    )
}
