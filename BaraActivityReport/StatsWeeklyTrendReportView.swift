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

    private func formattedDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let remainderMinutes = minutes % 60

        if hours > 0 {
            if remainderMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainderMinutes)m"
        }

        return "\(minutes)m"
    }

    private func barHeight(for minutes: Int) -> CGFloat {
        let minHeight: CGFloat = 12
        let maxHeight: CGFloat = 96
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
                        Text(formattedDuration(minutes: point.minutes))
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(height: 11)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.90, green: 0.66, blue: 0.68))
                            .frame(width: 24, height: barHeight(for: point.minutes))

                        Text(point.dayLabel)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 164, alignment: .bottom)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
