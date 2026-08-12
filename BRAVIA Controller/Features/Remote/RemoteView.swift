import SwiftUI

struct RemoteView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let buttonHeight: CGFloat = geometry.size.height < 520 ? 40 : 48
                let verticalButtonHeight = buttonHeight + (geometry.size.height < 520 ? 8 : 12)
                let spacing = sectionSpacing(
                    for: geometry.size.height,
                    buttonHeight: buttonHeight,
                    verticalButtonHeight: verticalButtonHeight
                )

                VStack(spacing: spacing) {
                    connectionHeader

                    HStack {
                        commandButton(
                            .power,
                            prominent: true,
                            prominentColor: Color(red: 0.10, green: 0.55, blue: 0.22),
                            height: buttonHeight
                        )
                        commandButton(.input, height: buttonHeight)
                    }

                    HStack {
                        commandButton(.back, height: buttonHeight)
                        commandButton(.home, height: buttonHeight)
                        commandButton(.options, height: buttonHeight)
                        commandButton(.androidMenu, height: buttonHeight)
                    }

                    HStack {
                        commandButton(.apps, height: buttonHeight)
                        commandButton(.youtube, foregroundColor: .red, height: buttonHeight)
                        commandButton(.netflix, foregroundColor: .red, height: buttonHeight)
                    }

                    DirectionPad(buttonHeight: buttonHeight, send: send)

                    HStack(spacing: 20) {
                        verticalControl(
                            title: "Volume",
                            upper: .volumeUp,
                            lower: .volumeDown,
                            height: verticalButtonHeight
                        )
                        commandButton(.mute, height: buttonHeight)
                        verticalControl(
                            title: "Channel",
                            upper: .channelUp,
                            lower: .channelDown,
                            height: verticalButtonHeight
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
            commandButton(upper, height: height, repeatsWhileHeld: true)
            commandButton(lower, height: height, repeatsWhileHeld: true)
        }
    }

    private func commandButton(
        _ command: TVCommand,
        prominent: Bool = false,
        prominentColor: Color = .accentColor,
        foregroundColor: Color = .primary,
        height: CGFloat,
        repeatsWhileHeld: Bool = false
    ) -> some View {
        RemoteCommandButton(
            command: command,
            prominent: prominent,
            prominentColor: prominentColor,
            foregroundColor: foregroundColor,
            minimumHeight: height,
            repeatsWhileHeld: repeatsWhileHeld
        ) {
            send(command)
        }
    }

    private func sectionSpacing(
        for availableHeight: CGFloat,
        buttonHeight: CGFloat,
        verticalButtonHeight: CGFloat
    ) -> CGFloat {
        // Seven content sections with six gaps. The estimate includes the
        // direction pad, volume/channel captions, and vertical padding.
        let fixedContentHeight = (buttonHeight * 7) + (verticalButtonHeight * 2) + 88
        return min(20, max(4, (availableHeight - fixedContentHeight) / 6))
    }

    private func send(_ command: TVCommand) {
        Task { await appModel.send(command) }
    }
}
