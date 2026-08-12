import Foundation

protocol CredentialStoring {
    func save(preSharedKey: String, for deviceID: UUID) throws
    func preSharedKey(for deviceID: UUID) throws -> String?
    func deletePreSharedKey(for deviceID: UUID)
}
