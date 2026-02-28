import SwiftUI

@main
struct BaraApp: App {
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootTabView(service: container.petStateService)
        }
    }
}
