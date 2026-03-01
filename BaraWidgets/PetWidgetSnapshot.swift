import Foundation

struct PetWidgetSnapshot: Equatable {
    let health: Int
    let imageName: String

    static func fromHealth(_ rawHealth: Int) -> PetWidgetSnapshot {
        let clamped = min(max(rawHealth, 0), 100)
        return PetWidgetSnapshot(
            health: clamped,
            imageName: imageName(for: clamped)
        )
    }

    private static func imageName(for health: Int) -> String {
        switch health {
        case 90...100:
            return "very_happy"
        case 80..<90:
            return "happy"
        case 50..<80:
            return "neutral"
        default:
            return "sad"
        }
    }
}
