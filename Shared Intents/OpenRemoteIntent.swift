import AppIntents

enum BRAVIAAppDestination: String, AppEnum {
    case remote

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "BRAVIA Controller")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .remote: "Remote"
    ]
}

struct OpenRemoteIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open BRAVIA Remote"

    @Parameter(title: "Destination")
    var target: BRAVIAAppDestination

    init() {
        target = .remote
    }
}
