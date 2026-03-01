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
    @State private var transitionEdge: Edge = .trailing
    @Environment(\.displayScale) private var displayScale
    private let weekChangeAnimation = Animation.interactiveSpring(response: 0.36, dampingFraction: 0.84, blendDuration: 0.16)

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

    private var canGoPreviousWeek: Bool {
        selectedWeekIndex > 0
    }

    private var canGoNextWeek: Bool {
        selectedWeekIndex < max(weeks.count - 1, 0)
    }

    @discardableResult
    private func goToPreviousWeek(emitHaptic: Bool = false) -> Bool {
        guard canGoPreviousWeek else { return false }
        transitionEdge = .leading
        withAnimation(weekChangeAnimation) {
            selectedWeekIndex -= 1
        }
        if emitHaptic {
            triggerSwipeHaptic()
        }
        return true
    }

    @discardableResult
    private func goToNextWeek(emitHaptic: Bool = false) -> Bool {
        guard canGoNextWeek else { return false }
        transitionEdge = .trailing
        withAnimation(weekChangeAnimation) {
            selectedWeekIndex += 1
        }
        if emitHaptic {
            triggerSwipeHaptic()
        }
        return true
    }

    private func handleHorizontalSwipe(translation: CGSize) {
        // Keep horizontal swipe intentional so vertical page scrolling stays smooth.
        guard abs(translation.width) > abs(translation.height) * 1.2,
              abs(translation.width) > 24 else { return }

        if translation.width < 0 {
            _ = goToNextWeek(emitHaptic: true)
        } else {
            _ = goToPreviousWeek(emitHaptic: true)
        }
    }

    private func triggerSwipeHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }

    private var reverseTransitionEdge: Edge {
        transitionEdge == .trailing ? .leading : .trailing
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
            Text("Calendar")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            HStack {
                Text(weekTitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        _ = goToPreviousWeek(emitHaptic: true)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
                    .disabled(!canGoPreviousWeek)
                    .opacity(canGoPreviousWeek ? 1 : 0.35)

                    Button {
                        _ = goToNextWeek(emitHaptic: true)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
                    .disabled(!canGoNextWeek)
                    .opacity(canGoNextWeek ? 1 : 0.35)
                }
            }

            if let currentWeek {
                ZStack {
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
                    .id(currentWeek.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: transitionEdge).combined(with: .opacity),
                            removal: .move(edge: reverseTransitionEdge).combined(with: .opacity)
                        )
                    )
                }
                .clipped()
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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 22)
            .onEnded { value in
                handleHorizontalSwipe(translation: value.translation)
            }
        )
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
