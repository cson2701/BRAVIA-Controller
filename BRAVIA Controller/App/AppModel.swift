import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var device: TVDevice?
    @Published private(set) var connectionState: TVConnectionState = .disconnected
    @Published private(set) var powerState: TVPowerState = .unknown
    @Published private(set) var systemInformation: TVSystemInformation?
    @Published private(set) var isLoadingSystemInformation = false
    @Published var presentedError: String?

    private let controller: any TVControlling
    private let credentialStore: any CredentialStoring
    private let defaults: UserDefaults
    private let savedDeviceKey = "savedTVDevice"
    private var statusRefreshTask: Task<Void, Never>?

    init(
        controller: (any TVControlling)? = nil,
        credentialStore: (any CredentialStoring)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.controller = controller ?? SonyTVClient()
        self.credentialStore = credentialStore ?? KeychainCredentialStore()
        self.defaults = defaults
        if let data = defaults.data(forKey: savedDeviceKey) {
            device = try? JSONDecoder().decode(TVDevice.self, from: data)
        }
    }

    func connect(host: String, preSharedKey: String) async {
        let normalizedHost = host
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var candidate = TVDevice(host: normalizedHost)
        connectionState = .connecting

        do {
            let status = try await controller.powerStatus(for: candidate, preSharedKey: preSharedKey)
            if let information = try? await controller.systemInformation(
                for: candidate,
                preSharedKey: preSharedKey
            ) {
                candidate.name = information.name
                candidate.model = information.model
                systemInformation = information
            }
            try credentialStore.save(preSharedKey: preSharedKey, for: candidate.id)
            device = candidate
            powerState = status
            connectionState = .connected
            persist(candidate)
        } catch {
            connectionState = .failed(error.localizedDescription)
            presentedError = error.localizedDescription
        }
    }

    func reconnect() async {
        await refreshStatus(markAsConnecting: true)
    }

    func refreshStatus() async {
        await refreshStatus(markAsConnecting: false)
    }

    private func refreshStatus(markAsConnecting: Bool) async {
        guard let device else { return }
        if markAsConnecting {
            connectionState = .connecting
        }
        do {
            guard let key = try credentialStore.preSharedKey(for: device.id) else {
                forgetDevice()
                return
            }
            powerState = try await controller.powerStatus(for: device, preSharedKey: key)
            if markAsConnecting,
               let information = try? await controller.systemInformation(
                   for: device,
                   preSharedKey: key
               ) {
                var updatedDevice = device
                updatedDevice.name = information.name
                updatedDevice.model = information.model
                self.device = updatedDevice
                systemInformation = information
                persist(updatedDevice)
            }
            connectionState = .connected
        } catch {
            connectionState = .failed(error.localizedDescription)
        }
    }

    func send(_ command: TVCommand) async {
        guard let device else { return }
        do {
            guard let key = try credentialStore.preSharedKey(for: device.id) else {
                throw SonyAPIError.invalidResponse
            }
            try await controller.send(command, to: device, preSharedKey: key)
            scheduleStatusRefresh()
        } catch {
            presentedError = error.localizedDescription
        }
    }

    func refreshSystemInformation() async {
        guard let device else { return }
        isLoadingSystemInformation = true
        defer { isLoadingSystemInformation = false }

        do {
            guard let key = try credentialStore.preSharedKey(for: device.id) else {
                throw SonyAPIError.invalidResponse
            }
            let information = try await controller.systemInformation(
                for: device,
                preSharedKey: key
            )
            systemInformation = information

            var updatedDevice = device
            updatedDevice.name = information.name
            updatedDevice.model = information.model
            self.device = updatedDevice
            persist(updatedDevice)
        } catch {
            presentedError = error.localizedDescription
        }
    }

    func forgetDevice() {
        statusRefreshTask?.cancel()
        statusRefreshTask = nil
        if let device {
            credentialStore.deletePreSharedKey(for: device.id)
        }
        defaults.removeObject(forKey: savedDeviceKey)
        device = nil
        powerState = .unknown
        systemInformation = nil
        connectionState = .disconnected
    }

    private func persist(_ device: TVDevice) {
        if let data = try? JSONEncoder().encode(device) {
            defaults.set(data, forKey: savedDeviceKey)
        }
    }

    private func scheduleStatusRefresh() {
        statusRefreshTask?.cancel()
        statusRefreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.refreshStatus()
        }
    }
}
