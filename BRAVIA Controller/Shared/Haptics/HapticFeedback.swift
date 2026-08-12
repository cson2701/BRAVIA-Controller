import UIKit

@MainActor
enum HapticFeedback {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
