import Foundation

struct TVDevice: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var model: String?
    var host: String
    var port: Int

    init(
        id: UUID = UUID(),
        name: String = "Sony BRAVIA",
        model: String? = nil,
        host: String,
        port: Int = 80
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.host = host
        self.port = port
    }

    var baseURL: URL? {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        return components.url
    }
}
