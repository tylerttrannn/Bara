import Foundation

struct PetSnapshot: Equatable {
    let hp: Double
    let mood: MoodState
    let distractingMinutesToday: Int
    let moodDescription: String
    let updatedAt: Date

    var hpDisplay: String {
        "\(Int(hp.rounded()))/100"
    }
}
