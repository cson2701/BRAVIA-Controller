import Foundation

struct DiscoveredTV: Hashable, Identifiable, Sendable {
    let name: String
    let model: String?
    let host: String
    let port: Int

    var id: String {
        "\(host):\(port)"
    }

    var displayTitle: String {
        guard let model, !model.isEmpty, model != name else { return name }
        return "\(name) (\(model))"
    }
}
