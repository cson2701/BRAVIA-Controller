import Foundation

struct TVSystemInformation: Decodable {
    let name: String
    let model: String
    let product: String?
    let region: String?
    let language: String?
    let serial: String?
    let macAddr: String?
    let generation: String?
    let area: String?
}
