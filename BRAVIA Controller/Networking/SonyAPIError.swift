import Foundation

enum SonyAPIError: LocalizedError {
    case invalidAddress
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            "The TV address is invalid."
        case .invalidResponse:
            "The TV returned an unexpected response."
        case .httpStatus(let status):
            "The TV returned HTTP status \(status). Check the address and pre-shared key."
        }
    }
}
