import SwiftUI

struct RemoteView: View {
    @ObservedObject var appModel: AppModel
    @State private var isShowingTVInformation = false

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
                    HStack {
                        commandButton(
                            .power,
                            prominent: true,
                            prominentColor: powerButtonColor,
                            outlineColor: powerButtonOutlineColor,
                            height: buttonHeight
                        )
                        commandButton(.androidMenu, height: buttonHeight)
                    }

                    HStack {
                        commandButton(.apps, height: buttonHeight)
                        commandButton(.youtube, foregroundColor: .red, height: buttonHeight)
                        commandButton(.netflix, foregroundColor: .red, height: buttonHeight)
                    }

                    HStack {
                        commandButton(.previous, height: buttonHeight)
                        commandButton(.play, height: buttonHeight)
                        commandButton(.pause, height: buttonHeight)
                        commandButton(.next, height: buttonHeight)
                    }

                    HStack {
                        commandButton(.input, height: buttonHeight)
                        Spacer(minLength: 32)
                        commandButton(.options, height: buttonHeight)
                    }

                    DirectionPad(buttonHeight: buttonHeight, send: send)

                    HStack {
                        commandButton(.back, height: buttonHeight)
                        Spacer(minLength: 32)
                        commandButton(.home, height: buttonHeight)
                    }

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

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        HapticFeedback.tap()
                        isShowingTVInformation = true
                    } label: {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(connectionColor)
                                .frame(width: 8, height: 8)
                            Text(appModel.device?.model ?? "BRAVIA Remote")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "\(appModel.device?.model ?? "BRAVIA Remote"), \(appModel.connectionState.label)"
                    )
                }
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
            .sheet(isPresented: $isShowingTVInformation) {
                TVInformationView(appModel: appModel)
            }
        }
    }

    private var connectionColor: Color {
        switch appModel.connectionState {
        case .connected:
            .green
        case .connecting:
            .orange
        case .failed:
            .red
        case .disconnected:
            .secondary
        }
    }

    private var powerButtonColor: Color {
        switch appModel.powerState {
        case .active:
            Color(red: 0.12, green: 0.58, blue: 0.24)
        case .standby:
            Color(red: 0.08, green: 0.38, blue: 0.16)
        case .unknown:
            Color(red: 0.10, green: 0.48, blue: 0.20)
        }
    }

    private var powerButtonOutlineColor: Color? {
        appModel.powerState == .active ? Color.green : nil
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
        outlineColor: Color? = nil,
        height: CGFloat,
        repeatsWhileHeld: Bool = false
    ) -> some View {
        RemoteCommandButton(
            command: command,
            prominent: prominent,
            prominentColor: prominentColor,
            foregroundColor: foregroundColor,
            outlineColor: outlineColor,
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
        let fixedContentHeight = (buttonHeight * 8) + (verticalButtonHeight * 2) + 56
        return min(20, max(4, (availableHeight - fixedContentHeight) / 6))
    }

    private func send(_ command: TVCommand) {
        Task { await appModel.send(command) }
    }
}
