import Foundation

enum TVCommand: String, CaseIterable, Identifiable {
    case power
    case input
    case home
    case options
    case androidMenu
    case apps
    case youtube
    case netflix
    case back
    case up
    case down
    case left
    case right
    case confirm
    case volumeUp
    case volumeDown
    case mute
    case channelUp
    case channelDown
    case play
    case pause
    case previous
    case next

    var id: String { rawValue }

    var title: String {
        switch self {
        case .power: "Power"
        case .input: "Input"
        case .home: "Home"
        case .options: "Options"
        case .androidMenu: "More"
        case .apps: "Apps"
        case .youtube: "YouTube"
        case .netflix: "Netflix"
        case .back: "Back"
        case .up: "Up"
        case .down: "Down"
        case .left: "Left"
        case .right: "Right"
        case .confirm: "OK"
        case .volumeUp: "Volume up"
        case .volumeDown: "Volume down"
        case .mute: "Mute"
        case .channelUp: "Channel up"
        case .channelDown: "Channel down"
        case .play: "Play"
        case .pause: "Pause"
        case .previous: "Previous"
        case .next: "Next"
        }
    }

    var systemImage: String {
        switch self {
        case .power: "power"
        case .input: "arrow.right.square.fill"
        case .home: "house.fill"
        case .options: "gearshape.fill"
        case .androidMenu: "list.bullet"
        case .apps: "square.grid.2x2.fill"
        case .youtube: "play.rectangle.fill"
        case .netflix: "film.fill"
        case .back: "arrow.uturn.backward"
        case .up: "chevron.up"
        case .down: "chevron.down"
        case .left: "chevron.left"
        case .right: "chevron.right"
        case .confirm: "circle.inset.filled"
        case .volumeUp: "speaker.plus.fill"
        case .volumeDown: "speaker.minus.fill"
        case .mute: "speaker.slash.fill"
        case .channelUp: "plus"
        case .channelDown: "minus"
        case .play: "play.fill"
        case .pause: "pause.fill"
        case .previous: "backward.end.fill"
        case .next: "forward.end.fill"
        }
    }

    var assetImageName: String? {
        switch self {
        case .youtube:
            "YouTubeIcon"
        case .netflix:
            "NetflixIcon"
        default:
            nil
        }
    }

    /// Fallback codes from Sony's IRCC-IP reference. A later discovery phase
    /// should replace these with values returned by getRemoteControllerInfo.
    var irccCode: String {
        switch self {
        case .power: "AAAAAQAAAAEAAAAVAw=="
        case .input: "AAAAAQAAAAEAAAAlAw=="
        case .home: "AAAAAQAAAAEAAABgAw=="
        case .options: "AAAAAgAAAJcAAAA2Aw=="
        case .androidMenu: "AAAAAgAAAMQAAABPAw=="
        case .apps: "AAAAAgAAAMQAAAAqAw=="
        case .youtube: "AAAAAgAAAMQAAABHAw=="
        case .netflix: "AAAAAgAAABoAAAB8Aw=="
        case .back: "AAAAAgAAAJcAAAAjAw=="
        case .up: "AAAAAQAAAAEAAAB0Aw=="
        case .down: "AAAAAQAAAAEAAAB1Aw=="
        case .left: "AAAAAQAAAAEAAAA0Aw=="
        case .right: "AAAAAQAAAAEAAAAzAw=="
        case .confirm: "AAAAAQAAAAEAAABlAw=="
        case .volumeUp: "AAAAAQAAAAEAAAASAw=="
        case .volumeDown: "AAAAAQAAAAEAAAATAw=="
        case .mute: "AAAAAQAAAAEAAAAUAw=="
        case .channelUp: "AAAAAQAAAAEAAAAQAw=="
        case .channelDown: "AAAAAQAAAAEAAAARAw=="
        case .play: "AAAAAgAAAJcAAAAaAw=="
        case .pause: "AAAAAgAAAJcAAAAZAw=="
        case .previous: "AAAAAgAAAJcAAAA8Aw=="
        case .next: "AAAAAgAAAJcAAAA9Aw=="
        }
    }
}
