//
//  SelectAppsModel.swift
//  Bara
//
//  Created by Tyler Tran on 2/28/26.
//

import Foundation
import FamilyControls

class AppSelectionModel {
    private static let defaults = AppGroupDefaults.sharedDefaults
    private static let key = AppGroupDefaults.appSelectionStorageKey

    static func setSelection(_ selection: FamilyActivitySelection) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(selection)
            defaults.set(data, forKey: key)
            print("Data saved sucessfully")
        } catch {
            print("error \(error.localizedDescription)")
        }
    }

    static func getSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: key) else {
            return FamilyActivitySelection()
        }
        
        let decoder = JSONDecoder()
        return (try? decoder.decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
    }

    static func clearSelection(defaults: UserDefaults = AppGroupDefaults.sharedDefaults) {
        defaults.removeObject(forKey: key)
    }
}
