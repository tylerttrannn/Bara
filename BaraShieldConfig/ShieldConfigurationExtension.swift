import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private let background = UIColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1.0)
    private let subtitleColor = UIColor(white: 0.82, alpha: 1.0)
    private let buttonColor = UIColor(red: 0.23, green: 0.62, blue: 0.52, alpha: 1.0)
    private let defaultIcon = UIImage(systemName: "hourglass")

    nonisolated override init() {
        super.init()
    }

    nonisolated override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(title: "\(application.localizedDisplayName ?? "App") blocked by Bara")
    }

    nonisolated override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(title: "Blocked by Bara")
    }

    nonisolated override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(title: "Blocked by Bara")
    }

    nonisolated override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(title: "Blocked by Bara")
    }

    nonisolated private func makeConfiguration(title: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemChromeMaterialDark,
            backgroundColor: background,
            icon: defaultIcon,
            title: .init(text: title, color: .white),
            subtitle: .init(
                text: "Blocked by Bara. Request extra minutes from a friend in Bara.",
                color: subtitleColor
            ),
            primaryButtonLabel: .init(text: "Close", color: .white),
            primaryButtonBackgroundColor: buttonColor
        )
    }
}
