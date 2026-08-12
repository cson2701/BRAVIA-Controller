import SwiftUI

struct RemoteCommandButton: View {
    let command: TVCommand
    var prominent = false
    var minimumHeight: CGFloat = 48
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.tap()
            action()
        } label: {
            Image(systemName: command.systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: minimumHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .tint(prominent ? .accentColor : Color.secondary.opacity(0.35))
        .accessibilityLabel(command.title)
    }
}
