import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct BaraApp: App {
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            AppLaunchContainerView(
                service: container.petStateService,
                buddyService: container.buddyService,
                allowanceStore: container.allowanceStore
            )
            .onAppear {
                let defaults = AppGroupDefaults.sharedDefaults
                if defaults.object(forKey: AppGroupDefaults.cachedHealth) == nil {
                    AppGroupDefaults.setCachedHealthValue(100, defaults: defaults)
                }
#if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                WidgetCenter.shared.reloadTimelines(ofKind: "BaraPetWidget")
#endif
            }
        }
    }
}
