import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import SwiftUI

enum SelectedActivityMetrics {
    private static let appGroupSuite = "group.com.Bara.appblocker"
    private static let selectionKey = "bara"

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    static func loadSelection() -> FamilyActivitySelection {
        guard let defaults = UserDefaults(suiteName: appGroupSuite),
              let data = defaults.data(forKey: selectionKey) else {
            return FamilyActivitySelection()
        }

        return (try? JSONDecoder().decode(FamilyActivitySelection.self, from: data))
            ?? FamilyActivitySelection()
    }

    static func hasSelection(_ selection: FamilyActivitySelection) -> Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    static func selectedDuration<S: AsyncSequence>(
        from data: S,
        selection: FamilyActivitySelection
    ) async -> TimeInterval where S.Element == DeviceActivityData {
        var totalDuration: TimeInterval = 0

        do {
            for try await activityData in data {
                for await segment in activityData.activitySegments {
                    for await category in segment.categories {
                        if let categoryToken = category.category.token,
                           selection.categoryTokens.contains(categoryToken) {
                            totalDuration += category.totalActivityDuration
                            continue
                        }

                        for await app in category.applications {
                            guard let appToken = app.application.token else { continue }
                            if selection.applicationTokens.contains(appToken) {
                                totalDuration += app.totalActivityDuration
                            }
                        }

                        for await webDomain in category.webDomains {
                            guard let webToken = webDomain.webDomain.token else { continue }
                            if selection.webDomainTokens.contains(webToken) {
                                totalDuration += webDomain.totalActivityDuration
                            }
                        }
                    }
                }
            }
        } catch {
            return totalDuration
        }

        return totalDuration
    }

    static func formatDuration(_ duration: TimeInterval) -> String {
        guard duration >= 60 else { return "0m" }
        return durationFormatter.string(from: duration) ?? "0m"
    }
}
