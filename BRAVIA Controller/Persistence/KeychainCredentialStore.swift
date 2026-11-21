import Foundation
import Security

final class KeychainCredentialStore: CredentialStoring {
    private let service: String
    private let accessGroup: String?

    init(service: String = Bundle.main.bundleIdentifier ?? "BRAVIA-Controller", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    private func query(account: String) -> [String: Any] {
        var attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        attributes[kSecAttrAccessGroup as String] = accessGroup
        return attributes
    }

    func save(preSharedKey: String, for deviceID: UUID) throws {
        try save(Data(preSharedKey.utf8), account: deviceID.uuidString)
    }

    func save(_ value: Data, account: String) throws {
        let query = query(account: account)
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: value] as CFDictionary)
        if status == errSecItemNotFound {
            var attributes = query
            attributes[kSecValueData as String] = value
            status = SecItemAdd(attributes as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    func preSharedKey(for deviceID: UUID) throws -> String? {
        try data(account: deviceID.uuidString).flatMap { String(data: $0, encoding: .utf8) }
    }

    func data(account: String) throws -> Data? {
        var query = query(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unhandled(status)
        }
        return data
    }

    func deletePreSharedKey(for deviceID: UUID) {
        try? delete(account: deviceID.uuidString)
    }

    func delete(account: String) throws {
        let status = SecItemDelete(query(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }
}

private enum KeychainError: LocalizedError {
    case unhandled(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unhandled(let status):
            "Keychain operation failed with status \(status)."
        }
    }
}
