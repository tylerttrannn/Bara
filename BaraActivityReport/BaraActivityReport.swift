//
//  BaraActivityReport.swift
//  BaraActivityReport
//
//  Created by Tyler Tran on 2/27/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct BaraActivityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        StatsTodayCardReport { value in
            StatsSummaryCardReportView(title: "Today", value: value)
        }
        StatsWeeklyAverageCardReport { value in
            StatsSummaryCardReportView(title: "Weekly avg", value: value)
        }
        StatsWeeklyTrendReport { points in
            StatsWeeklyTrendReportView(points: points)
        }
        StatsMoodCalendarReport { weeks in
            StatsMoodCalendarReportView(weeks: weeks)
        }
        StatsTopAppsReport { topApps in
            StatsTopAppsReportView(topApps: topApps)
        }
        // Add more reports here...
    }
}
