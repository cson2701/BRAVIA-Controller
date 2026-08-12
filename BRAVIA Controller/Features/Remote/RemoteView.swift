import SwiftUI

struct RemoteView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let buttonHeight: CGFloat = geometry.size.height < 520 ? 40 : 48
                let spacing = sectionSpacing(for: geometry.size.height, buttonHeight: buttonHeight)

                VStack(spacing: spacing) {
                    connectionHeader

                    HStack {
                        commandButton(.power, prominent: true, height: buttonHeight)
                            .tint(.red)
                        commandButton(.input, height: buttonHeight)
                    }

                    HStack {
                        commandButton(.back, height: buttonHeight)
                        commandButton(.home, height: buttonHeight)
                        commandButton(.options, height: buttonHeight)
                    }

                    DirectionPad(buttonHeight: buttonHeight, send: send)

                    HStack(spacing: 20) {
                        verticalControl(
                            title: "Volume",
                            upper: .volumeUp,
                            lower: .volumeDown,
                            height: buttonHeight
                        )
                        commandButton(.mute, height: buttonHeight)
                        verticalControl(
                            title: "Channel",
                            upper: .channelUp,
                            lower: .channelDown,
                            height: buttonHeight
                        )
                    }

                    HStack {
                        commandButton(.previous, height: buttonHeight)
                        commandButton(.play, height: buttonHeight)
                        commandButton(.pause, height: buttonHeight)
                        commandButton(.next, height: buttonHeight)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle(appModel.device?.name ?? "BRAVIA Remote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reconnect") {
                            HapticFeedback.tap()
                            Task { await appModel.reconnect() }
                        }
                        Button("Forget TV", role: .destructive) {
                            HapticFeedback.tap()
                            appModel.forgetDevice()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded { HapticFeedback.tap() }
                    )
                }
            }
            .task {
                await appModel.reconnect()
            }
        }
    }

    private var connectionHeader: some View {
        HStack {
            Circle()
                .fill(appModel.connectionState == .connected ? .green : .orange)
                .frame(width: 9, height: 9)
            Text(appModel.connectionState.label)
            Spacer()
            Text(appModel.powerState.rawValue.capitalized)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func verticalControl(
        title: String,
        upper: TVCommand,
        lower: TVCommand,
        height: CGFloat
    ) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            commandButton(upper, height: height)
            commandButton(lower, height: height)
        }
    }

    private func commandButton(
        _ command: TVCommand,
        prominent: Bool = false,
        height: CGFloat
    ) -> some View {
        RemoteCommandButton(
            command: command,
            prominent: prominent,
            minimumHeight: height
        ) {
            send(command)
        }
    }

    private func sectionSpacing(for availableHeight: CGFloat, buttonHeight: CGFloat) -> CGFloat {
        // Six content sections with five gaps. The estimate includes the
        // direction pad, volume/channel captions, and vertical padding.
        let fixedContentHeight = (buttonHeight * 8) + 88
        return min(20, max(4, (availableHeight - fixedContentHeight) / 5))
    }

    private func send(_ command: TVCommand) {
        Task { await appModel.send(command) }
    }
}
