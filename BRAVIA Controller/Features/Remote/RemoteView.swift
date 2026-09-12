import SwiftUI

struct RemoteView: View {
    @Environment(\.scenePhase) private var scenePhase
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
                        volumeControl(height: verticalButtonHeight)
                        commandButton(
                            .mute,
                            prominent: appModel.volumeInformation?.mute == true,
                            prominentColor: .primary,
                            prominentForegroundColor: Color(uiColor: .systemBackground),
                            height: buttonHeight
                        )
                        .accessibilityValue(muteAccessibilityValue)
                        channelControl(height: verticalButtonHeight)
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
                            Text(appModel.device?.displayTitle ?? "BRAVIA Remote")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "\(appModel.device?.displayTitle ?? "BRAVIA Remote"), \(appModel.connectionState.label)"
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
            .background(alignment: .topLeading) {
                HardwareVolumeButtonHandler(
                    isEnabled: scenePhase == .active && appModel.connectionState == .connected,
                    onVolumeUp: { send(.volumeUp) },
                    onVolumeDown: { send(.volumeDown) }
                )
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
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

    private func volumeControl(height: CGFloat) -> some View {
        VStack {
            commandButton(.volumeUp, height: height, repeatsWhileHeld: true)
            HStack(spacing: 5) {
                Image(systemName: appModel.volumeInformation?.outputSystemImage ?? "speaker.wave.2.fill")
                Text(appModel.volumeInformation.map { String($0.volume) } ?? "–")
                    .monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(height: 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(volumeAccessibilityLabel)
            commandButton(.volumeDown, height: height, repeatsWhileHeld: true)
        }
    }

    private var volumeAccessibilityLabel: String {
        guard let information = appModel.volumeInformation else {
            return "Audio output and volume unknown"
        }
        return "\(information.outputLabel), volume \(information.volume)"
    }

    private var muteAccessibilityValue: String {
        guard let information = appModel.volumeInformation else {
            return "Status unknown"
        }
        return information.mute ? "Muted" : "Not muted"
    }

    private func channelControl(height: CGFloat) -> some View {
        VStack {
            commandButton(.channelUp, height: height, repeatsWhileHeld: true)
            Text("Channel")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(height: 16)
            commandButton(.channelDown, height: height, repeatsWhileHeld: true)
        }
    }

    private func commandButton(
        _ command: TVCommand,
        prominent: Bool = false,
        prominentColor: Color = .accentColor,
        prominentForegroundColor: Color = .white,
        foregroundColor: Color = .primary,
        outlineColor: Color? = nil,
        height: CGFloat,
        repeatsWhileHeld: Bool = false
    ) -> some View {
        RemoteCommandButton(
            command: command,
            prominent: prominent,
            prominentColor: prominentColor,
            prominentForegroundColor: prominentForegroundColor,
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
