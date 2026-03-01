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
    private let defaults = UserDefaults(suiteName: "group.com.Bara.appblocker")
    private let thresholdMinutesKey = "bara.threshold.minutes"

    func startActivity(){
        let monitor = DeviceActivityCenter()
        let activityName = DeviceActivityName("baraLimit")
        let eventName = DeviceActivityEvent.Name("baraLimit")
        let thresholdMinutes = max(defaults?.integer(forKey: thresholdMinutesKey) ?? 30, 1)
        let thresholdHours = thresholdMinutes / 60
        let thresholdRemainderMinutes = thresholdMinutes % 60

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute : 59),
            repeats: true
        )
        
        let event = DeviceActivityEvent(
            applications : AppSelectionModel.getSelection().applicationTokens,
            // HELP
            threshold : DateComponents(hour: thresholdHours, minute: thresholdRemainderMinutes)
        )
   
        do {
            try monitor.startMonitoring(
                activityName,
                during : schedule,
                events: [eventName: event]
            )
            print("activity started with threshold \(thresholdMinutes)m")
        } catch{
            print("error starting activity \(error.localizedDescription)")
        }
    }
}
    
    
