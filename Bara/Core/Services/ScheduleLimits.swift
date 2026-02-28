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
    func startActivity(){
        let monitor = DeviceActivityCenter()
        let activityName = DeviceActivityName("baraLimit")
        let eventName = DeviceActivityEvent.Name("baraLimit")

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute : 59),
            repeats: true
        )
        
        let event = DeviceActivityEvent(
            applications : AppSelectionModel.getSelection().applicationTokens,
            threshold : DateComponents(hour : 0, minute : 1)
        )
   
        do {
            try monitor.startMonitoring(
                activityName,
                during : schedule,
                events: [eventName: event]
            )
            print("activity started")
        } catch{
            print("error starting activity \(error.localizedDescription)")
        }
    }
}
    
    

