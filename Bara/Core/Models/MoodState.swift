import SwiftUI

enum MoodState: String, CaseIterable, Codable {
    case happy
    case neutral
    case sad
    case distressed

    var title: String {
        switch self {
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .distressed: return "Distressed"
        }
    }

    var symbolName: String {
        switch self {
        case .happy: return "face.smiling"
        case .neutral: return "face.dashed"
        case .sad: return "cloud.drizzle"
        case .distressed: return "exclamationmark.triangle"
        }
    }

    var tint: Color {
        switch self {
        case .happy: return AppColors.moodHappy
        case .neutral: return AppColors.moodNeutral
        case .sad: return AppColors.moodSad
        case .distressed: return AppColors.moodDistressed
        }
    }
}
