//
//  TotalActivityView.swift
//  BaraActivityReport
//
//  Created by Tyler Tran on 2/27/26.
//

import SwiftUI

struct TotalActivityView: View {
    let totalActivity: String
    
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
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
