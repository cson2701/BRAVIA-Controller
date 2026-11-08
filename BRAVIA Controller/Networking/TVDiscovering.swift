import Foundation

protocol TVDiscovering {
    func discover() async throws -> [DiscoveredTV]
}
