import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var device: TVDevice?
    @Published private(set) var connectionState: TVConnectionState = .disconnected
    @Published private(set) var powerState: TVPowerState = .unknown
    @Published private(set) var volumeInformation: TVVolumeInformation?
    @Published private(set) var systemInformation: TVSystemInformation?
    @Published private(set) var isLoadingSystemInformation = false
    @Published private(set) var discoveredTVs: [DiscoveredTV] = []
    @Published private(set) var isDiscovering = false
    @Published private(set) var discoveryMessage: String?
    @Published var presentedError: String?
    @Published private var remoteCommandCodes: [TVCommand: String]?

    private let controller: any TVControlling
    private let discoveryService: any TVDiscovering
    private let credentialStore: any CredentialStoring
    private let defaults: UserDefaults
    private let savedDeviceKey = "savedTVDevice"
    private var statusRefreshTask: Task<Void, Never>?

    init(
        controller: (any TVControlling)? = nil,
        discoveryService: (any TVDiscovering)? = nil,
        credentialStore: (any CredentialStoring)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.controller = controller ?? SonyTVClient()
        self.discoveryService = discoveryService ?? SonyTVDiscoveryService()
        self.credentialStore = credentialStore ?? KeychainCredentialStore()
        self.defaults = defaults
        if let data = defaults.data(forKey: savedDeviceKey) {
            device = try? JSONDecoder().decode(TVDevice.self, from: data)
        }
    }

    func discoverTVs() async {
        guard !isDiscovering else { return }
        isDiscovering = true
        discoveryMessage = nil

        do {
            discoveredTVs = try await discoveryService.discover()
            if discoveredTVs.isEmpty {
                discoveryMessage = "No BRAVIA TVs found. Make sure the TV is on and connected to the same Wi-Fi network."
            }
        } catch {
            discoveredTVs = []
            discoveryMessage = error.localizedDescription
        }
        isDiscovering = false
    }

    func connect(host: String, port: Int = 80, preSharedKey: String) async {
        let normalizedHost = host
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let candidate = TVDevice(host: normalizedHost, port: port)
        connectionState = .connecting

        do {
            let status = try await controller.powerStatus(for: candidate, preSharedKey: preSharedKey)
            async let reportedCodes = try? controller.remoteCommandCodes(
                for: candidate,
                preSharedKey: preSharedKey
            )
            volumeInformation = try? await controller.volumeInformation(
                for: candidate,
                preSharedKey: preSharedKey
            )
            let information = try? await controller.systemInformation(
                for: candidate,
                preSharedKey: preSharedKey
            )
            let codes = await reportedCodes
            try credentialStore.save(preSharedKey: preSharedKey, for: candidate.id)
            var savedDevice = candidate
            if let information {
                savedDevice.name = information.name
                savedDevice.model = information.model
            }
            systemInformation = information
            remoteCommandCodes = codes
            device = savedDevice
            powerState = status
            connectionState = .connected
            persist(savedDevice)
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
        let shouldRefreshCodes = markAsConnecting || (remoteCommandCodes == nil && connectionState != .connected)
        if markAsConnecting {
            connectionState = .connecting
        }
        do {
            guard let key = try credentialStore.preSharedKey(for: device.id) else {
                forgetDevice()
                return
            }
            let status = try await controller.powerStatus(for: device, preSharedKey: key)
            guard self.device?.id == device.id else { return }
            powerState = status
            let volume = try? await controller.volumeInformation(
                for: device,
                preSharedKey: key
            )
            let information = markAsConnecting
                ? try? await controller.systemInformation(for: device, preSharedKey: key)
                : nil
            let codes = shouldRefreshCodes
                ? try? await controller.remoteCommandCodes(for: device, preSharedKey: key)
                : nil
            guard var updatedDevice = self.device, updatedDevice.id == device.id else { return }
            volumeInformation = volume
            if let codes {
                remoteCommandCodes = codes
            }
            if let information {
                updatedDevice.name = information.name
                updatedDevice.model = information.model
                self.device = updatedDevice
                systemInformation = information
                persist(updatedDevice)
            }
            connectionState = .connected
        } catch {
            guard self.device?.id == device.id else { return }
            connectionState = .failed(error.localizedDescription)
        }
    }

    func supports(_ command: TVCommand) -> Bool {
        irccCode(for: command) != nil
    }

    private func irccCode(for command: TVCommand) -> String? {
        if let remoteCommandCodes {
            return remoteCommandCodes[command]
        }
        return command.fallbackIRCCCode
    }

    func send(_ command: TVCommand) async {
        guard let device, let code = irccCode(for: command) else { return }
        do {
            guard let key = try credentialStore.preSharedKey(for: device.id) else {
                throw SonyAPIError.invalidResponse
            }
            try await controller.sendIRCC(code, to: device, preSharedKey: key)
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

    func renameDevice(_ title: String?) {
        guard var device else { return }
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        device.customTitle = normalizedTitle?.isEmpty == false ? normalizedTitle : nil
        self.device = device
        persist(device)
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
        volumeInformation = nil
        systemInformation = nil
        remoteCommandCodes = nil
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
