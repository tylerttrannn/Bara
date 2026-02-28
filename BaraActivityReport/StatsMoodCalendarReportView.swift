import SwiftUI
import UIKit
import ImageIO

enum BaraDailyMood: Hashable, Sendable {
    case unknown
    case veryHappy
    case happy
    case neutral
    case sad
    case distressed

    var imageName: String {
        switch self {
        case .unknown:
            return "capy_default"
        case .veryHappy:
            return "capy_very_happy"
        case .happy:
            return "capy_happy"
        case .neutral:
            return "capy_neutral"
        case .sad:
            return "capy_sad"
        case .distressed:
            return "capy_sad"
        }
    }

    var fallbackSymbol: String {
        switch self {
        case .unknown:
            return "questionmark.circle.fill"
        case .veryHappy:
            return "sparkles"
        case .happy:
            return "face.smiling"
        case .neutral:
            return "face.dashed"
        case .sad:
            return "cloud.drizzle"
        case .distressed:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct MoodCalendarDay: Identifiable, Hashable, Sendable {
    let dayStart: Date
    let minutes: Int?
    let mood: BaraDailyMood

    var id: Date { dayStart }
}

struct MoodCalendarWeek: Identifiable, Hashable, Sendable {
    let weekStart: Date
    let weekEnd: Date
    let days: [MoodCalendarDay]

    var id: Date { weekStart }
}

struct StatsMoodCalendarReportView: View {
    let weeks: [MoodCalendarWeek]
    @State private var selectedWeekIndex: Int
    @Environment(\.displayScale) private var displayScale

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let monthShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter
    }()

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("d")
        return formatter
    }()

    private let rangeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    init(weeks: [MoodCalendarWeek]) {
        self.weeks = weeks
        _selectedWeekIndex = State(initialValue: max(weeks.count - 1, 0))
    }

    private var currentWeek: MoodCalendarWeek? {
        guard weeks.indices.contains(selectedWeekIndex) else { return nil }
        return weeks[selectedWeekIndex]
    }

    private var weekTitle: String {
        guard let currentWeek else { return "No weeks available" }
        let start = rangeDateFormatter.string(from: currentWeek.weekStart)
        let end = rangeDateFormatter.string(from: currentWeek.weekEnd)
        return "\(start) - \(end)"
    }

    @ViewBuilder
    private func moodImage(for mood: BaraDailyMood) -> some View {
        if let uiImage = CapybaraImageLoader.image(
            named: mood.imageName,
            targetSize: 44,
            scale: displayScale
        ) {
            Image(uiImage: uiImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Image(systemName: mood.fallbackSymbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .padding(5)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bara Mood Calendar")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            HStack {
                Text(weekTitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        if selectedWeekIndex > 0 {
                            selectedWeekIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
                    .disabled(selectedWeekIndex == 0)
                    .opacity(selectedWeekIndex == 0 ? 0.35 : 1)

                    Button {
                        if selectedWeekIndex < max(weeks.count - 1, 0) {
                            selectedWeekIndex += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
                    .disabled(selectedWeekIndex >= max(weeks.count - 1, 0))
                    .opacity(selectedWeekIndex >= max(weeks.count - 1, 0) ? 0.35 : 1)
                }
            }

            if let currentWeek {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(currentWeek.days) { day in
                        VStack(spacing: 6) {
                            moodImage(for: day.mood)
                                .frame(width: 34, height: 34)

                            Text(monthShortFormatter.string(from: day.dayStart).uppercased())
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)

                            Text(dayFormatter.string(from: day.dayStart))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.98, green: 0.95, blue: 0.89))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            } else {
                Text("No data yet")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .onChange(of: weeks.count) { _, _ in
            selectedWeekIndex = min(selectedWeekIndex, max(weeks.count - 1, 0))
        }
    }
}

private enum CapybaraImageLoader {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(named name: String, targetSize: CGFloat, scale: CGFloat) -> UIImage? {
        let cacheKey = "\(name)-\(Int(targetSize))-\(Int(scale * 100))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        guard let fileURL = Bundle.main.url(forResource: name, withExtension: "png"),
              let source = CGImageSourceCreateWithURL(fileURL as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }

        let resolvedScale = max(scale, 1.0)
        let maxPixel = max(Int(targetSize * resolvedScale), 32)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let image = UIImage(cgImage: cgImage)
        cache.setObject(image, forKey: cacheKey)
        return image
    }
}
