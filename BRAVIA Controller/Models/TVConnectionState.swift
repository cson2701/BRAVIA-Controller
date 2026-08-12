import Foundation

enum TVConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)

    var label: String {
        switch self {
        case .disconnected:
            "Disconnected"
        case .connecting:
            "Connecting…"
        case .connected:
            "Connected"
        case .failed:
            "Connection failed"
        }
    }
}

enum TVPowerState: String, Codable {
    case active
    case standby
    case unknown
}
