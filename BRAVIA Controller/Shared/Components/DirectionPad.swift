import SwiftUI

struct DirectionPad: View {
    var buttonHeight: CGFloat = 48
    let send: (TVCommand) -> Void

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Color.clear
                button(.up)
                Color.clear
            }
            GridRow {
                button(.left)
                button(.confirm)
                button(.right)
            }
            GridRow {
                Color.clear
                button(.down)
                Color.clear
            }
        }
        .frame(maxWidth: 280)
    }

    private func button(_ command: TVCommand) -> some View {
        RemoteCommandButton(
            command: command,
            minimumHeight: buttonHeight,
            repeatsWhileHeld: command != .confirm
        ) {
            send(command)
        }
    }
}
