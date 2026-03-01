import UIKit

@MainActor
enum Haptics {
    private static let selectionCooldown: TimeInterval = 0.06
    private static let impactCooldown: TimeInterval = 0.12
    private static let notificationCooldown: TimeInterval = 0.25

    private static var lastSelectionAt: TimeInterval = 0
    private static var lastImpactAt: TimeInterval = 0
    private static var lastNotificationAt: TimeInterval = 0

    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func selection() {
        guard shouldFire(lastFiredAt: &lastSelectionAt, cooldown: selectionCooldown) else { return }
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard shouldFire(lastFiredAt: &lastImpactAt, cooldown: impactCooldown) else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: max(0, min(intensity, 1)))
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard shouldFire(lastFiredAt: &lastNotificationAt, cooldown: notificationCooldown) else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }

    private static func shouldFire(lastFiredAt: inout TimeInterval, cooldown: TimeInterval) -> Bool {
        guard isAppActive else { return false }

        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastFiredAt >= cooldown else { return false }
        lastFiredAt = now
        return true
    }

    private static var isAppActive: Bool {
#if APP_EXTENSION
        return false
#else
        return UIApplication.shared.applicationState == .active
#endif
    }
}
