import Darwin
import Foundation

@MainActor
final class SonyTVDiscoveryService: NSObject, TVDiscovering {
    private let scanDuration: Duration
    private var browser: NetServiceBrowser?
    private var resolvingServices: [NetService] = []
    private var devicesByID: [String: DiscoveredTV] = [:]
    private var continuation: CheckedContinuation<[DiscoveredTV], Error>?
    private var finishTask: Task<Void, Never>?

    init(scanDuration: Duration = .seconds(4)) {
        self.scanDuration = scanDuration
    }

    func discover() async throws -> [DiscoveredTV] {
        finishTask?.cancel()
        browser?.stop()
        resolvingServices.forEach { $0.stop() }

        devicesByID = [:]
        resolvingServices = []

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let browser = NetServiceBrowser()
            browser.delegate = self
            self.browser = browser
            browser.searchForServices(ofType: "_googlecast._tcp.", inDomain: "local.")

            finishTask = Task { [weak self, scanDuration] in
                try? await Task.sleep(for: scanDuration)
                guard !Task.isCancelled else { return }
                self?.finish()
            }
        }
    }

    private func finish(throwing error: Error? = nil) {
        browser?.stop()
        browser = nil
        resolvingServices.forEach { $0.stop() }
        resolvingServices = []
        finishTask?.cancel()
        finishTask = nil

        guard let continuation else { return }
        self.continuation = nil

        if let error {
            continuation.resume(throwing: error)
        } else {
            let devices = devicesByID.values.sorted {
                $0.displayTitle.localizedStandardCompare($1.displayTitle) == .orderedAscending
            }
            continuation.resume(returning: devices)
        }
    }

    private func addResolvedService(_ service: NetService) {
        let textRecord = Self.textRecord(for: service)
        let name = textRecord["fn"] ?? service.name
        let model = textRecord["md"]

        guard Self.looksLikeBravia(name: name, model: model),
              let host = Self.ipv4Address(for: service) else {
            return
        }

        let device = DiscoveredTV(
            name: name.isEmpty ? "Sony BRAVIA" : name,
            model: model,
            host: host,
            port: 80
        )
        devicesByID[device.id] = device
    }

    private static func looksLikeBravia(name: String, model: String?) -> Bool {
        let identity = "\(name) \(model ?? "")".uppercased()
        return identity.contains("BRAVIA")
            || identity.contains("SONY")
            || identity.contains("KD-")
            || identity.contains("KDL-")
            || identity.contains("XR-")
    }

    private static func textRecord(for service: NetService) -> [String: String] {
        guard let data = service.txtRecordData() else { return [:] }
        return NetService.dictionary(fromTXTRecord: data).reduce(into: [:]) { result, entry in
            if let value = String(data: entry.value, encoding: .utf8) {
                result[entry.key.lowercased()] = value
            }
        }
    }

    private static func ipv4Address(for service: NetService) -> String? {
        for addressData in service.addresses ?? [] {
            let family = addressData.withUnsafeBytes { buffer -> sa_family_t? in
                buffer.baseAddress?.assumingMemoryBound(to: sockaddr.self).pointee.sa_family
            }
            guard family == sa_family_t(AF_INET) else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = addressData.withUnsafeBytes { buffer -> Int32 in
                guard let baseAddress = buffer.baseAddress else { return EAI_FAIL }
                return getnameinfo(
                    baseAddress.assumingMemoryBound(to: sockaddr.self),
                    socklen_t(addressData.count),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
            }
            if result == 0 {
                return String(cString: host)
            }
        }
        return nil
    }
}

extension SonyTVDiscoveryService: NetServiceBrowserDelegate {
    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        resolvingServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 3)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        let error = NSError(
            domain: NetService.errorDomain,
            code: errorDict[NetService.errorCode]?.intValue ?? -1,
            userInfo: [
                NSLocalizedDescriptionKey: "Could not browse for TVs on the local network. Check Local Network access in Settings."
            ]
        )
        finish(throwing: error)
    }
}

extension SonyTVDiscoveryService: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        addResolvedService(sender)
        sender.stop()
    }
}
