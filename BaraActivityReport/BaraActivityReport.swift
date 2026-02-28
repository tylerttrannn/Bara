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
        // Add more reports here...
    }
}
