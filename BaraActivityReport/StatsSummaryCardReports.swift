import DeviceActivity
import ExtensionKit
import Foundation
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let statsTodayCard = Self("Stats Today Card")
    static let statsWeeklyAverageCard = Self("Stats Weekly Average Card")
    static let statsWeeklyTrendChart = Self("Stats Weekly Trend Chart")
    static let statsMoodCalendar = Self("Stats Mood Calendar")
    static let statsTopApps = Self("Stats Top Apps")
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

struct StatsWeeklyTrendReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .statsWeeklyTrendChart
    let content: ([StatsTrendPoint]) -> StatsWeeklyTrendReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> [StatsTrendPoint] {
        let dayStarts = recentDayStarts(count: 7)
        let entries = await dailyUsageEntries(from: data, dayStarts: dayStarts)

        let labelFormatter = DateFormatter()
        labelFormatter.locale = Locale.current
        labelFormatter.setLocalizedDateFormatFromTemplate("EEE")

        return entries.map { entry in
            StatsTrendPoint(
                dayStart: entry.dayStart,
                dayLabel: labelFormatter.string(from: entry.dayStart),
                minutes: entry.minutes
            )
        }
    }
}

struct StatsMoodCalendarReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .statsMoodCalendar
    let content: ([MoodCalendarWeek]) -> StatsMoodCalendarReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> [MoodCalendarWeek] {
        await moodCalendarWeeks(from: data)
    }
}

struct StatsTopAppsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .statsTopApps
    let content: ([TopAppUsageEntry]) -> StatsTopAppsReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> [TopAppUsageEntry] {
        await topAppUsageEntries(from: data)
    }
}

private struct DailyUsageEntry {
    let dayStart: Date
    let minutes: Int
    let hasData: Bool
}

private func recentDayStarts(count: Int) -> [Date] {
    let calendar = Calendar.current
    let todayStart = calendar.startOfDay(for: Date())

    return (0..<count).compactMap { offset in
        calendar.date(byAdding: .day, value: -(count - 1 - offset), to: todayStart)
    }
}

private func dayStartsForRecentWeeks(weekCount: Int) -> [Date] {
    let calendar = Calendar.current
    let todayStart = calendar.startOfDay(for: Date())
    let latestWeekStart = calendar.dateInterval(of: .weekOfYear, for: todayStart)?.start ?? todayStart
    let oldestWeekStart = calendar.date(byAdding: .weekOfYear, value: -(weekCount - 1), to: latestWeekStart) ?? latestWeekStart

    return (0..<(weekCount * 7)).compactMap { dayOffset in
        calendar.date(byAdding: .day, value: dayOffset, to: oldestWeekStart)
    }
}

private func dailyUsageEntries<S: AsyncSequence>(
    from data: S,
    dayStarts: [Date]
) async -> [DailyUsageEntry] where S.Element == DeviceActivityData {
    let calendar = Calendar.current
    var durationsByDay = Dictionary(uniqueKeysWithValues: dayStarts.map { ($0, TimeInterval.zero) })
    var hasDataByDay = Dictionary(uniqueKeysWithValues: dayStarts.map { ($0, false) })

    do {
        for try await activityData in data {
            for await segment in activityData.activitySegments {
                let dayStart = calendar.startOfDay(for: segment.dateInterval.start)
                if durationsByDay[dayStart] != nil {
                    durationsByDay[dayStart, default: 0] += segment.totalActivityDuration
                    hasDataByDay[dayStart] = true
                }
            }
        }
    } catch {
        return dayStarts.map { dayStart in
            DailyUsageEntry(dayStart: dayStart, minutes: 0, hasData: false)
        }
    }

    return dayStarts.map { dayStart in
        DailyUsageEntry(
            dayStart: dayStart,
            minutes: Int((durationsByDay[dayStart] ?? 0) / 60.0),
            hasData: hasDataByDay[dayStart] ?? false
        )
    }
}

private func moodFor(entry: DailyUsageEntry) -> BaraDailyMood {
    guard entry.hasData else { return .unknown }

    switch entry.minutes {
    case ..<60:
        return .veryHappy
    case 60..<120:
        return .happy
    case 120..<180:
        return .neutral
    case 180..<240:
        return .sad
    default:
        return .distressed
    }
}

private func moodCalendarWeeks<S: AsyncSequence>(
    from data: S
) async -> [MoodCalendarWeek] where S.Element == DeviceActivityData {
    let dayStarts = dayStartsForRecentWeeks(weekCount: 12)
    let entries = await dailyUsageEntries(from: data, dayStarts: dayStarts)
    guard !entries.isEmpty else { return [] }

    let weekCount = entries.count / 7
    var weeks: [MoodCalendarWeek] = []
    weeks.reserveCapacity(weekCount)

    for weekIndex in 0..<weekCount {
        let startIndex = weekIndex * 7
        let endIndex = startIndex + 7
        let weekSlice = Array(entries[startIndex..<endIndex])
        guard let firstDay = weekSlice.first?.dayStart,
              let lastDay = weekSlice.last?.dayStart else {
            continue
        }

        let moodDays = weekSlice.map { entry in
            MoodCalendarDay(
                dayStart: entry.dayStart,
                minutes: entry.hasData ? entry.minutes : nil,
                mood: moodFor(entry: entry)
            )
        }

        weeks.append(
            MoodCalendarWeek(
                weekStart: firstDay,
                weekEnd: lastDay,
                days: moodDays
            )
        )
    }

    return weeks
}

private func topAppUsageEntries<S: AsyncSequence>(
    from data: S
) async -> [TopAppUsageEntry] where S.Element == DeviceActivityData {
    var durationsByAppID: [String: TimeInterval] = [:]
    var namesByAppID: [String: String] = [:]
    var tokensByAppID: [String: ApplicationToken] = [:]

    do {
        for try await activityData in data {
            for await segment in activityData.activitySegments {
                for await category in segment.categories {
                    for await appActivity in category.applications {
                        let app = appActivity.application
                        let bundleID = app.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let localizedName = app.localizedDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)

                        let appID: String
                        if let bundleID, !bundleID.isEmpty {
                            appID = bundleID
                        } else if let localizedName, !localizedName.isEmpty {
                            appID = localizedName
                        } else {
                            appID = "unknown.app"
                        }

                        let displayName: String
                        if let localizedName, !localizedName.isEmpty {
                            displayName = localizedName
                        } else if let bundleID, !bundleID.isEmpty {
                            displayName = bundleID
                        } else {
                            displayName = "Unknown App"
                        }

                        durationsByAppID[appID, default: 0] += appActivity.totalActivityDuration
                        namesByAppID[appID] = displayName
                        if let token = app.token {
                            tokensByAppID[appID] = token
                        }
                    }
                }
            }
        }
    } catch {
        return []
    }

    return durationsByAppID
        .map { appID, duration in
            TopAppUsageEntry(
                id: appID,
                token: tokensByAppID[appID],
                name: namesByAppID[appID] ?? "Unknown App",
                minutes: Int(duration / 60.0)
            )
        }
        .sorted { lhs, rhs in
            if lhs.minutes == rhs.minutes {
                return lhs.name < rhs.name
            }
            return lhs.minutes > rhs.minutes
        }
}
