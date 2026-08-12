import SwiftUI

struct RemoteCommandButton: View {
    let command: TVCommand
    var prominent = false
    var prominentColor: Color = .accentColor
    var foregroundColor: Color = .primary
    var outlineColor: Color?
    var minimumHeight: CGFloat = 48
    var repeatsWhileHeld = false
    let action: () -> Void

    @State private var isPressed = false
    @State private var isTrackingPress = false
    @State private var isCancelled = false
    @State private var buttonSize: CGSize = .zero
    @State private var pressTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: command.systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(prominent ? Color.white : foregroundColor)
            .frame(maxWidth: .infinity, minHeight: minimumHeight)
            .background(
                prominent ? prominentColor : Color.secondary.opacity(0.2),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                if let outlineColor {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(outlineColor, lineWidth: 3)
                        .padding(-3)
                }
            }
            .opacity(isPressed ? 0.7 : 1)
            .scaleEffect(isPressed ? 0.97 : 1)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in updatePress(at: value.location) }
                    .onEnded { value in finishPress(at: value.location) }
            )
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                buttonSize = newSize
            }
            .onAppear { HapticFeedback.prepareForButtonPress() }
            .onDisappear { cancelPress() }
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                HapticFeedback.tap()
                action()
            }
        .accessibilityLabel(command.title)
    }

    private func beginPress() {
        guard !isPressed else { return }
        isPressed = true
        HapticFeedback.buttonDown()

        if repeatsWhileHeld {
            action()
            pressTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                while !Task.isCancelled {
                    HapticFeedback.repeatTick()
                    action()
                    try? await Task.sleep(for: .milliseconds(140))
                }
            }
        }
    }

    private func updatePress(at location: CGPoint) {
        if !isTrackingPress {
            isTrackingPress = true
            isCancelled = false
            beginPress()
            return
        }

        guard !isCancelled, !buttonBounds.contains(location) else { return }
        isCancelled = true
        cancelPressEffects()
    }

    private func finishPress(at location: CGPoint) {
        let shouldPerformAction = !isCancelled && buttonBounds.contains(location)
        if shouldPerformAction {
            endPress()
        } else {
            cancelPressEffects()
        }
        isTrackingPress = false
        isCancelled = false
    }

    private func endPress() {
        guard isPressed else { return }
        isPressed = false
        pressTask?.cancel()
        pressTask = nil
        HapticFeedback.buttonUp()

        if !repeatsWhileHeld {
            action()
        }
    }

    private func cancelPress() {
        cancelPressEffects()
        isTrackingPress = false
        isCancelled = false
    }

    private func cancelPressEffects() {
        pressTask?.cancel()
        pressTask = nil
        isPressed = false
    }

    private var buttonBounds: CGRect {
        CGRect(origin: .zero, size: buttonSize)
    }

}
