import DeviceActivity
import ExtensionKit
import Foundation
import SwiftUI

extension DeviceActivityReport.Context {
    static let statsTodayCard = Self("Stats Today Card")
    static let statsWeeklyAverageCard = Self("Stats Weekly Average Card")
}

struct StatsTodayCardReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .statsTodayCard
    let content: (String) -> StatsSummaryCardReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        let totalDuration = await data
            .flatMap { $0.activitySegments }
            .reduce(0) { partialResult, segment in
                partialResult + segment.totalActivityDuration
            }
        return SelectedActivityMetrics.formatDuration(totalDuration)
    }
}

struct StatsWeeklyAverageCardReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .statsWeeklyAverageCard
    let content: (String) -> StatsSummaryCardReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        let totalDuration = await data
            .flatMap { $0.activitySegments }
            .reduce(0) { partialResult, segment in
                partialResult + segment.totalActivityDuration
            }
        let averageDuration = totalDuration / 7.0
        return SelectedActivityMetrics.formatDuration(averageDuration)
    }
}
