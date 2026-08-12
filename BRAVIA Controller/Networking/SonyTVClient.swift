import Foundation

final class SonyTVClient: TVControlling {
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func powerStatus(for device: TVDevice, preSharedKey: String) async throws -> TVPowerState {
        let requestBody = SonyRPCRequest(
            method: "getPowerStatus",
            params: [String](),
            id: 1,
            version: "1.0"
        )
        let request = try makeRequest(
            device: device,
            path: "sony/system",
            preSharedKey: preSharedKey,
            body: encoder.encode(requestBody)
        )
        let (data, response) = try await session.data(for: request)
        try validate(response)

        let payload = try decoder.decode(SonyPowerStatusResponse.self, from: data)
        guard let status = payload.result?.first?.status else {
            throw SonyAPIError.invalidResponse
        }
        return TVPowerState(rawValue: status) ?? .unknown
    }

    func send(_ command: TVCommand, to device: TVDevice, preSharedKey: String) async throws {
        let body = """
        <?xml version="1.0"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
          <s:Body>
            <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
              <IRCCCode>\(command.irccCode)</IRCCCode>
            </u:X_SendIRCC>
          </s:Body>
        </s:Envelope>
        """
        guard let data = body.data(using: .utf8) else {
            throw SonyAPIError.invalidResponse
        }
        var request = try makeRequest(
            device: device,
            path: "sony/ircc",
            preSharedKey: preSharedKey,
            body: data
        )
        request.setValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"",
            forHTTPHeaderField: "SOAPACTION"
        )

        let (_, response) = try await session.data(for: request)
        try validate(response)
    }

    private func makeRequest(
        device: TVDevice,
        path: String,
        preSharedKey: String,
        body: Data
    ) throws -> URLRequest {
        guard let url = device.baseURL?.appending(path: path) else {
            throw SonyAPIError.invalidAddress
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 5
        request.httpBody = body
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue(preSharedKey, forHTTPHeaderField: "X-Auth-PSK")
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SonyAPIError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw SonyAPIError.httpStatus(httpResponse.statusCode)
        }
    }
}

private struct SonyRPCRequest<Parameters: Encodable>: Encodable {
    let method: String
    let params: Parameters
    let id: Int
    let version: String
}

private struct SonyPowerStatusResponse: Decodable {
    let result: [SonyPowerStatus]?
}

private struct SonyPowerStatus: Decodable {
    let status: String
}
