import Foundation
import SwiftUI
import WidgetKit

struct BRAVIAControllerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "scrapps.BRAVIA-Controller.open-remote"
        ) {
            ControlWidgetButton(action: OpenRemoteIntent()) {
                Label("BRAVIA Remote", systemImage: "appletvremote.gen3")
            }
        }
        .displayName("BRAVIA Remote")
        .description("Open the BRAVIA remote control.")
    }
}

protocol BRAVIATVCommandControl: ControlWidget {
    static var command: TVCommand { get }
    static var displayName: LocalizedStringResource { get }
}

extension BRAVIATVCommandControl {
    var body: some ControlWidgetConfiguration {
        let command = Self.command
        let displayName = Self.displayName
        return StaticControlConfiguration(kind: "scrapps.BRAVIA-Controller.command.\(command.rawValue)") {
            ControlWidgetButton(action: SendTVCommandIntent(command: command)) {
                Label {
                    Text(displayName)
                } icon: {
                    Image(systemName: command.systemImage)
                }
            }
        }
        .displayName(displayName)
        .description("Send a command to your saved Sony BRAVIA.")
    }
}

struct BRAVIAPowerControl: BRAVIATVCommandControl {
    static let command = TVCommand.power
    static let displayName: LocalizedStringResource = "BRAVIA Power"
}

struct BRAVIAMuteControl: BRAVIATVCommandControl {
    static let command = TVCommand.mute
    static let displayName: LocalizedStringResource = "BRAVIA Mute"
}

struct BRAVIAVolumeUpControl: BRAVIATVCommandControl {
    static let command = TVCommand.volumeUp
    static let displayName: LocalizedStringResource = "BRAVIA Volume Up"
}

struct BRAVIAVolumeDownControl: BRAVIATVCommandControl {
    static let command = TVCommand.volumeDown
    static let displayName: LocalizedStringResource = "BRAVIA Volume Down"
}

struct BRAVIAInputControl: BRAVIATVCommandControl {
    static let command = TVCommand.input
    static let displayName: LocalizedStringResource = "BRAVIA Input"
}

struct BRAVIAUpControl: BRAVIATVCommandControl {
    static let command = TVCommand.up
    static let displayName: LocalizedStringResource = "BRAVIA Up"
}

struct BRAVIASettingsControl: BRAVIATVCommandControl {
    static let command = TVCommand.options
    static let displayName: LocalizedStringResource = "BRAVIA Settings"
}

struct BRAVIALeftControl: BRAVIATVCommandControl {
    static let command = TVCommand.left
    static let displayName: LocalizedStringResource = "BRAVIA Left"
}

struct BRAVIAOKControl: BRAVIATVCommandControl {
    static let command = TVCommand.confirm
    static let displayName: LocalizedStringResource = "BRAVIA OK"
}

struct BRAVIARightControl: BRAVIATVCommandControl {
    static let command = TVCommand.right
    static let displayName: LocalizedStringResource = "BRAVIA Right"
}

struct BRAVIABackControl: BRAVIATVCommandControl {
    static let command = TVCommand.back
    static let displayName: LocalizedStringResource = "BRAVIA Back"
}

struct BRAVIADownControl: BRAVIATVCommandControl {
    static let command = TVCommand.down
    static let displayName: LocalizedStringResource = "BRAVIA Down"
}

struct BRAVIAHomeControl: BRAVIATVCommandControl {
    static let command = TVCommand.home
    static let displayName: LocalizedStringResource = "BRAVIA Home"
}
