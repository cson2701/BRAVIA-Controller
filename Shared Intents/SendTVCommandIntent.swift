import AppIntents
import Foundation

struct SendTVCommandIntent: AppIntent {
    static let title: LocalizedStringResource = "Send BRAVIA Remote Command"
    static let supportedModes: IntentModes = .background
    static let isDiscoverable = false

    @Parameter(title: "Command")
    var commandName: String

    init() {}

    init(command: TVCommand) {
        commandName = command.rawValue
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let configuration = try WidgetTVConfiguration.load() else {
            throw WidgetCommandError.setupRequired
        }
        guard let command = TVCommand(rawValue: commandName),
              let code = command.irccCode(reported: configuration.remoteCommandCodes)
        else {
            throw WidgetCommandError.unsupportedCommand
        }

        try await SonyTVClient().sendIRCC(
            code,
            to: configuration.device,
            preSharedKey: configuration.preSharedKey
        )
        if command == .power {
            // Give the TV time to transition before WidgetKit reads its power status.
            try? await Task.sleep(for: .milliseconds(800))
        }
        return .result()
    }
}

private enum WidgetCommandError: LocalizedError {
    case setupRequired
    case unsupportedCommand

    var errorDescription: String? {
        switch self {
        case .setupRequired: "Open BRAVIA Controller and connect your TV first."
        case .unsupportedCommand: "This button is unavailable for your TV."
        }
    }
}
