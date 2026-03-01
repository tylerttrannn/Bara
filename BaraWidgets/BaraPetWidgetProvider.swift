import WidgetKit
import SwiftUI

struct BaraPetWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: PetWidgetSnapshot
}

struct BaraPetWidgetProvider: TimelineProvider {
    private enum DefaultsKey {
        static let suiteCandidates = ["group.com.Bara.appblocker", "group.com.bara.appblocker", "group.Bara"]
        static let health = "bara.user.health.cached"
        static let legacyHealth = "bara.pet.hp"
    }

    func placeholder(in context: Context) -> BaraPetWidgetEntry {
        BaraPetWidgetEntry(date: Date(), snapshot: .fromHealth(100))
    }

    func getSnapshot(in context: Context, completion: @escaping (BaraPetWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BaraPetWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> BaraPetWidgetEntry {
        let defaults = appGroupDefaults()
        let rawHealth: Int
        if let defaults {
            if defaults.object(forKey: DefaultsKey.health) != nil {
                rawHealth = max(0, min(defaults.integer(forKey: DefaultsKey.health), 100))
            } else if defaults.object(forKey: DefaultsKey.legacyHealth) != nil {
                let legacy = defaults.double(forKey: DefaultsKey.legacyHealth)
                let normalized = max(0, min(Int(legacy.rounded()), 100))
                rawHealth = normalized
                defaults.set(normalized, forKey: DefaultsKey.health)
            } else {
                rawHealth = 100
            }
        } else {
            rawHealth = 100
        }

        return BaraPetWidgetEntry(
            date: Date(),
            snapshot: .fromHealth(rawHealth)
        )
    }

    private func appGroupDefaults() -> UserDefaults? {
        for suite in DefaultsKey.suiteCandidates {
            if let defaults = UserDefaults(suiteName: suite) {
                return defaults
            }
        }

        return nil
    }
}
