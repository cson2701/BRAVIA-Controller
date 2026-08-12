import SwiftUI

struct RemoteCommandButton: View {
    let command: TVCommand
    var prominent = false
    var prominentColor: Color = .accentColor
    var minimumHeight: CGFloat = 48
    var repeatsWhileHeld = false
    let action: () -> Void

    @State private var isPressed = false
    @State private var pressTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: command.systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: minimumHeight)
            .background(
                prominent ? prominentColor : Color.secondary.opacity(0.2),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .opacity(isPressed ? 0.7 : 1)
            .scaleEffect(isPressed ? 0.97 : 1)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in beginPress() }
                    .onEnded { _ in endPress() }
            )
            .onDisappear { cancelPress() }
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { perform(action) }
        .accessibilityLabel(command.title)
    }

    private func beginPress() {
        guard !isPressed else { return }
        isPressed = true

        if repeatsWhileHeld {
            perform(action)
            pressTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                while !Task.isCancelled {
                    perform(action)
                    try? await Task.sleep(for: .milliseconds(140))
                }
            }
        }
    }

    private func endPress() {
        guard isPressed else { return }
        isPressed = false
        pressTask?.cancel()
        pressTask = nil

        if !repeatsWhileHeld {
            perform(action)
        }
    }

    private func cancelPress() {
        pressTask?.cancel()
        pressTask = nil
        isPressed = false
    }

    private func perform(_ action: () -> Void) {
        HapticFeedback.tap()
        action()
    }
}
