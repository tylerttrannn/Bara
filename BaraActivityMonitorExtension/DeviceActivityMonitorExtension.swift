//
//  DeviceActivityMonitorExtension.swift
//  BaraActivityMonitorExtension
//
//  Created by Tyler Tran on 2/27/26.
//

import DeviceActivity
import FamilyControls
import Foundation
import UserNotifications
import ManagedSettings

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private enum Names {
        static let borrowActivity = DeviceActivityName("baraBorrowLimit")
    }

    private enum DefaultsKey {
        static let selection = "bara"
        static let buddyUnblockActive = "bara.buddy.unblock.active"
        static let blockNow = "blocknow"
        static let unblockNow = "unblocknow"
    }
    
    let defaults = UserDefaults(suiteName: "group.com.Bara.appblocker")
    let alertStore = ManagedSettingsStore()
    let content = UNMutableNotificationContent()
      
    func decodeSelection() -> FamilyActivitySelection? {
        guard let defaults = defaults else {
            return nil
        }

        guard let data = defaults.data(forKey: DefaultsKey.selection) else {
            return nil
        }

        let decoder = JSONDecoder()
        do {
            let selection = try decoder.decode(FamilyActivitySelection.self, from: data)
            return selection
        } catch {
            return nil
        }
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        if consumeUnblockNowIfNeeded() {
            clearShields()
            return
        }

        // One-shot manual block trigger from app-side Settings button.
        if consumeBlockNowIfNeeded() {
            applyShieldsIfSelectionExists()
            return
        }

        if isBuddyUnblockActive() {
            clearShields()
            return
        }

        clearShields()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        clearShields()
        if activity == Names.borrowActivity {
            setBuddyUnblockActive(false)
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        if consumeUnblockNowIfNeeded() {
            clearShields()
            return
        }

        // Safety path in case blockNow is toggled right before threshold callback.
        if consumeBlockNowIfNeeded() {
            applyShieldsIfSelectionExists()
            return
        }

        let unblockActive = isBuddyUnblockActive()

        if !unblockActive {
            applyShieldsIfSelectionExists()
            return
        }

        if activity == Names.borrowActivity {
            setBuddyUnblockActive(false)
            applyShieldsIfSelectionExists()
            return
        }

        // During active buddy unblock, ignore non-borrow threshold events.
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Handle the warning before the interval starts.
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Handle the warning before the interval ends.
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        
        // Handle the warning before the event reaches its threshold.
    }

    func clearShields() {
        alertStore.shield.applications = nil
        alertStore.shield.applicationCategories = nil
        alertStore.shield.webDomains = nil
    }

    func applyShieldsIfSelectionExists() {
        guard let selection = decodeSelection() else { return }
        alertStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        alertStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        alertStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    func isBuddyUnblockActive() -> Bool {
        defaults?.bool(forKey: DefaultsKey.buddyUnblockActive) == true
    }

    func setBuddyUnblockActive(_ value: Bool) {
        defaults?.set(value, forKey: DefaultsKey.buddyUnblockActive)
    }

    func consumeBlockNowIfNeeded() -> Bool {
        guard defaults?.bool(forKey: DefaultsKey.blockNow) == true else {
            return false
        }

        defaults?.set(false, forKey: DefaultsKey.blockNow)
        return true
    }

    func consumeUnblockNowIfNeeded() -> Bool {
        guard defaults?.bool(forKey: DefaultsKey.unblockNow) == true else {
            return false
        }

        defaults?.set(false, forKey: DefaultsKey.unblockNow)
        return true
    }
}
