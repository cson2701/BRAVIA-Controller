import Foundation

protocol TVControlling {
    func powerStatus(for device: TVDevice, preSharedKey: String) async throws -> TVPowerState
    func systemInformation(
        for device: TVDevice,
        preSharedKey: String
    ) async throws -> TVSystemInformation
    func volumeInformation(
        for device: TVDevice,
        preSharedKey: String
    ) async throws -> TVVolumeInformation
    func send(_ command: TVCommand, to device: TVDevice, preSharedKey: String) async throws
}
