import Foundation

struct TVVolumeInformation: Decodable, Equatable {
    let target: String
    let volume: Int
    let mute: Bool
    let maxVolume: Int
    let minVolume: Int

    var outputSystemImage: String {
        let normalizedTarget = target.lowercased()
        if normalizedTarget.contains("headphone") {
            return "headphones"
        }
        if normalizedTarget.contains("bluetooth") {
            return "bluetooth"
        }
        return "speaker.wave.2.fill"
    }

    var outputLabel: String {
        let normalizedTarget = target.lowercased()
        if normalizedTarget.contains("headphone") {
            return "Headphones"
        }
        if normalizedTarget.contains("bluetooth") {
            return "Bluetooth audio"
        }
        return "TV speakers"
    }
}
