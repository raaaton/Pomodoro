import UIKit

@MainActor
enum HapticManager {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func intervalCompleted() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
