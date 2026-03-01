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
    
    let defaults = UserDefaults(suiteName: "group.com.Bara.appblocker")
    let alertStore = ManagedSettingsStore()
    let content = UNMutableNotificationContent()
      
    func decodeSelection() -> FamilyActivitySelection? {
        guard let defaults = defaults else {
            return nil
        }

        guard let data = defaults.data(forKey: "bara") else {
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
        if let selection = decodeSelection() {
           alertStore.shield.applications = selection.applicationTokens
           alertStore.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        // Handle the start of the interval.
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Handle the end of the interval.
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        
        if let selection = decodeSelection() {
           alertStore.shield.applications = selection.applicationTokens
           alertStore.shield.applicationCategories = .specific(selection.categoryTokens)
        }
                
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
}
