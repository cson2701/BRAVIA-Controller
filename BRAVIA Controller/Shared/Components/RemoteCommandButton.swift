import SwiftUI

struct RemoteCommandButton: View {
    let command: TVCommand
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.tap()
            action()
        } label: {
            Image(systemName: command.systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .tint(prominent ? .accentColor : Color.secondary.opacity(0.35))
        .accessibilityLabel(command.title)
    }
}
