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
    func remoteCommandCodes(for device: TVDevice, preSharedKey: String) async throws -> [TVCommand: String]
    func sendIRCC(_ code: String, to device: TVDevice, preSharedKey: String) async throws
}
