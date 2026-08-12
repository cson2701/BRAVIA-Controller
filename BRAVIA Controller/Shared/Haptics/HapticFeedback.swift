import UIKit

@MainActor
enum HapticFeedback {
    private static let pressGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let repeatGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let releaseGenerator = UISelectionFeedbackGenerator()

    static func prepareForButtonPress() {
        pressGenerator.prepare()
        repeatGenerator.prepare()
        releaseGenerator.prepare()
    }

    static func buttonDown() {
        pressGenerator.impactOccurred(intensity: 0.8)
        repeatGenerator.prepare()
    }

    static func buttonUp() {
        releaseGenerator.selectionChanged()
        pressGenerator.prepare()
    }

    static func repeatTick() {
        repeatGenerator.impactOccurred(intensity: 0.55)
        repeatGenerator.prepare()
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
