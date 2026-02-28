import SwiftUI

struct TrendPlaceholderChartView: View {
    let trend: [DayUsagePoint]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("7-Day Trend")
                .font(AppTypography.subtitle)

            HStack(alignment: .bottom, spacing: Spacing.small) {
                ForEach(trend) { point in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.accentTeal.opacity(0.75))
                            .frame(width: 24, height: CGFloat(max(point.minutes, 12)))
                        Text(point.dayLabel)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

#Preview {
    PreviewContainer {
        TrendPlaceholderChartView(
            trend: [
                DayUsagePoint(dayLabel: "Mon", minutes: 74),
                DayUsagePoint(dayLabel: "Tue", minutes: 68),
                DayUsagePoint(dayLabel: "Wed", minutes: 102),
                DayUsagePoint(dayLabel: "Thu", minutes: 89),
                DayUsagePoint(dayLabel: "Fri", minutes: 120),
                DayUsagePoint(dayLabel: "Sat", minutes: 96),
                DayUsagePoint(dayLabel: "Sun", minutes: 63)
            ]
        )
        .padding()
    }
}
