//
//  ScheduleLimits.swift
//  Bara
//
//  Created by Tyler Tran on 2/28/26.
//

import Foundation
import DeviceActivity
import FamilyControls

class ScheduleLimits {
    private let defaults: UserDefaults
    private let allowanceStore: BorrowAllowanceProviding

    init(
        defaults: UserDefaults = AppGroupDefaults.sharedDefaults,
        allowanceStore: BorrowAllowanceProviding? = nil
    ) {
        self.defaults = defaults
        self.allowanceStore = allowanceStore ?? AppGroupBorrowAllowanceStore(defaults: defaults)
    }

    func startActivity() {
        let monitor = DeviceActivityCenter()
        let activityName = DeviceActivityName("baraLimit")
        let eventName = DeviceActivityEvent.Name("baraLimit")

        let baseThreshold = max(defaults.integer(forKey: AppGroupDefaults.thresholdMinutes), 1)
        let bonusMinutes = allowanceStore.activeAllowance(now: Date())?.minutes ?? 0
        let effectiveThreshold = baseThreshold + bonusMinutes

        let thresholdHours = effectiveThreshold / 60
        let thresholdRemainderMinutes = effectiveThreshold % 60

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: AppSelectionModel.getSelection().applicationTokens,
            threshold: DateComponents(hour: thresholdHours, minute: thresholdRemainderMinutes)
        )

        do {
            try monitor.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )

            if bonusMinutes > 0 {
                allowanceStore.consumeAllowance()
            }

            print("activity started with threshold \(effectiveThreshold)m (base \(baseThreshold)m + bonus \(bonusMinutes)m)")
        } catch {
            print("error starting activity \(error.localizedDescription)")
        }
    }
}
