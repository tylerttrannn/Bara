//
//  TotalActivityView.swift
//  BaraActivityReport
//
//  Created by Tyler Tran on 2/27/26.
//

import SwiftUI
import ManagedSettings
import FamilyControls

struct TotalActivityView: View {
    let totalActivity: String
    
    let defaults = UserDefaults(suiteName: "group.Bara")
    let alertStore = ManagedSettingsStore()
      
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's distracting time")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)

            Text(totalActivity)
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Keep it low to cheer up Bara.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
