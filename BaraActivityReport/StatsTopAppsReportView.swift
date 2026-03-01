import SwiftUI
import FamilyControls
import ManagedSettings

struct TopAppUsageEntry: Identifiable, Hashable {
    let id: String
    let token: ApplicationToken?
    let name: String
    let minutes: Int
}

struct StatsTopAppsReportView: View {
    let topApps: [TopAppUsageEntry]
    private let appIconSize: CGFloat = 30

    private let formatter: DateComponentsFormatter = {
        let value = DateComponentsFormatter()
        value.allowedUnits = [.hour, .minute]
        value.unitsStyle = .abbreviated
        value.zeroFormattingBehavior = .dropAll
        return value
    }()

    private func formattedDuration(minutes: Int) -> String {
        let seconds = TimeInterval(minutes * 60)
        return formatter.string(from: seconds) ?? "\(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top App Usage")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Text("Last 7 days")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)

            if topApps.isEmpty {
                Text("No app usage available yet.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(Array(topApps.prefix(3).enumerated()), id: \.element.id) { index, app in
                    HStack(spacing: 10) {
                        Text("\(index + 1).")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .leading)

                        if let token = app.token {
                            Label(token)
                                .labelStyle(.iconOnly)
                                .frame(width: appIconSize, height: appIconSize)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: appIconSize, height: appIconSize)
                        }

                        Text(app.name)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(formattedDuration(minutes: app.minutes))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
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
