import SwiftUI

@main
struct BaraApp: App {
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            AppLaunchContainerView(service: container.petStateService)
        }
    }
}
