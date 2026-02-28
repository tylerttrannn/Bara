//
//  TotalActivityReport.swift
//  BaraActivityReport
//
//  Created by Tyler Tran on 2/27/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    // Define which context your scene will represent.
    let context: DeviceActivityReport.Context = .totalActivity
    
    // Define the custom configuration and the resulting view for this report.
    let content: (String) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        let selection = SelectedActivityMetrics.loadSelection()
        guard SelectedActivityMetrics.hasSelection(selection) else { return "0m" }

        let totalDuration = await SelectedActivityMetrics.selectedDuration(
            from: data,
            selection: selection
        )
        return SelectedActivityMetrics.formatDuration(totalDuration)
    }
}
