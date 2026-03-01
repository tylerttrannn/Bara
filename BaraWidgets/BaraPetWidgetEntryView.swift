import SwiftUI
import UIKit
import WidgetKit

struct BaraPetWidgetEntryView: View {
    let entry: BaraPetWidgetEntry

    var body: some View {
        VStack(spacing: 10) {
            moodImage
                .frame(height: 74)

            VStack(spacing: 2) {
                Text("Health")
                    .font(.caption)
                    .foregroundStyle(.white)

                Text("\(entry.snapshot.health)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.19, green: 0.24, blue: 0.22), Color(red: 0.11, green: 0.14, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var moodImage: some View {
        if let uiImage = moodUIImage(named: entry.snapshot.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "face.smiling")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                .padding(8)
        }
    }

    private func moodUIImage(named name: String) -> UIImage? {
        let bundle = Bundle.main
        if let path = bundle.path(forResource: name, ofType: "png"),
           let fileImage = UIImage(contentsOfFile: path) {
            return fileImage
        }

        return UIImage(named: name, in: bundle, with: nil)
    }
}
#Preview("BaraPetWidgetEntryView") {
    BaraPetWidgetEntryView(
        entry: BaraPetWidgetEntry(
            date: Date(),
            snapshot: .fromHealth(87)
        )
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}
