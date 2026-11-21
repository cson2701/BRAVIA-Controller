import Foundation

struct WidgetTVConfiguration: Codable, Equatable {
    static let kind = "scrapps.BRAVIA-Controller.home-remote"
    private static let account = "savedTV"

    let device: TVDevice
    let remoteCommandCodes: [TVCommand: String]?
    let preSharedKey: String

    private static func store() throws -> KeychainCredentialStore {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "BRAVIAWidgetKeychainGroup") as? String,
              !group.isEmpty
        else {
            throw CocoaError(.featureUnsupported)
        }
        return KeychainCredentialStore(service: kind, accessGroup: group)
    }

    static func load() throws -> Self? {
        guard let data = try store().data(account: account) else { return nil }
        return try JSONDecoder().decode(Self.self, from: data)
    }

    func publish() throws -> Bool {
        if (try? Self.load()) == self { return false }
        try Self.store().save(JSONEncoder().encode(self), account: Self.account)
        return true
    }

    static func clear() throws {
        try store().delete(account: account)
    }
}
