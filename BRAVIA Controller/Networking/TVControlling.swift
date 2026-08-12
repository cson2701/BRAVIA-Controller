import Foundation

protocol TVControlling {
    func powerStatus(for device: TVDevice, preSharedKey: String) async throws -> TVPowerState
    func send(_ command: TVCommand, to device: TVDevice, preSharedKey: String) async throws
}
