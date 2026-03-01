//
//  ScheduleLimits.swift
//  Bara
//
//  Created by Tyler Tran on 2/28/26.
//

import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

class ScheduleLimits {
    private enum Names {
        static let baseActivity = DeviceActivityName("baraLimit")
        static let baseEvent = DeviceActivityEvent.Name("baraLimit")
        static let borrowActivity = DeviceActivityName("baraBorrowLimit")
        static let borrowEvent = DeviceActivityEvent.Name("baraBorrowLimit")
    }

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
        defaults.set(false, forKey: AppGroupDefaults.buddyUnblockActive)

        let baseThreshold = max(defaults.integer(forKey: AppGroupDefaults.thresholdMinutes), 1)
        let effectiveThreshold = baseThreshold

        let threshold = thresholdComponents(for: effectiveThreshold)

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: AppSelectionModel.getSelection().applicationTokens,
            threshold: threshold
        )

        do {
            try monitor.startMonitoring(
                Names.baseActivity,
                during: schedule,
                events: [Names.baseEvent: event]
            )

            print("activity started with base threshold \(baseThreshold)m")
        } catch {
            print("error starting activity \(error.localizedDescription)")
        }
    }

    func activateBorrowAllowanceIfAvailable() {
        guard let allowance = allowanceStore.activeAllowance(now: Date()) else {
            return
        }

        activateBorrowAllowance(minutes: allowance.minutes)
    }

    @discardableResult
    func activateBorrowAllowance(minutes: Int) -> Bool {
        let bonusMinutes = max(minutes, 1)
        let monitor = DeviceActivityCenter()

        var start = Calendar.current.dateComponents([.hour, .minute], from: Date())
        start.second = 0

        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: false
        )

        let event = DeviceActivityEvent(
            applications: AppSelectionModel.getSelection().applicationTokens,
            threshold: thresholdComponents(for: bonusMinutes)
        )

        do {
            defaults.set(true, forKey: AppGroupDefaults.buddyUnblockActive)
            clearAllShields()

            try monitor.startMonitoring(
                Names.borrowActivity,
                during: schedule,
                events: [Names.borrowEvent: event]
            )

            allowanceStore.consumeAllowance()
            print("borrow allowance activated for \(bonusMinutes)m")
            return true
        } catch {
            defaults.set(false, forKey: AppGroupDefaults.buddyUnblockActive)
            print("error activating borrow allowance \(error.localizedDescription)")
            return false
        }
    }

    func clearShieldsAndDisableBuddyUnblock() {
        defaults.set(false, forKey: AppGroupDefaults.buddyUnblockActive)
        clearAllShields()
    }

    private func thresholdComponents(for minutes: Int) -> DateComponents {
        let hours = minutes / 60
        let remainder = minutes % 60
        return DateComponents(hour: hours, minute: remainder)
    }

    private func clearAllShields() {
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
