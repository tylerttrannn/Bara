import Foundation

struct DayUsagePoint: Identifiable, Equatable {
    let id = UUID()
    let dayLabel: String
    let minutes: Int
}

struct CategoryUsage: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let minutes: Int
}

struct UsageSnapshot: Equatable {
    let todayMinutes: Int
    let weeklyAverageMinutes: Int
    let trend: [DayUsagePoint]
    let categoryBreakdown: [CategoryUsage]
}
