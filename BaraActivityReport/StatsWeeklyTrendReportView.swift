import SwiftUI

struct StatsTrendPoint: Identifiable, Hashable, Sendable {
    let dayStart: Date
    let dayLabel: String
    let minutes: Int

    var id: Date { dayStart }
}

struct StatsWeeklyTrendReportView: View {
    let points: [StatsTrendPoint]

    private var maxMinutes: Int {
        max(points.map(\.minutes).max() ?? 0, 1)
    }

    private func barHeight(for minutes: Int) -> CGFloat {
        let minHeight: CGFloat = 12
        let maxHeight: CGFloat = 110
        let scaled = CGFloat(minutes) / CGFloat(maxMinutes) * maxHeight
        return max(minHeight, scaled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Trend")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(points) { point in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.92, green: 0.62, blue: 0.34))
                            .frame(width: 24, height: barHeight(for: point.minutes))

                        Text(point.dayLabel)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
