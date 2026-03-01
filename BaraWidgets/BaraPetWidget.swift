import WidgetKit
import SwiftUI

struct BaraPetWidget: Widget {
    static let kind = "BaraPetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: BaraPetWidgetProvider()) { entry in
            BaraPetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bara Health")
        .description("See Bara's health at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
