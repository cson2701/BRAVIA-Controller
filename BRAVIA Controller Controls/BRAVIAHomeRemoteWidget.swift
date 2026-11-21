import AppIntents
import SwiftUI
import WidgetKit

struct BRAVIAHomeRemoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetTVConfiguration.kind, provider: RemoteWidgetProvider()) { entry in
            RemoteWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(uiColor: .secondarySystemBackground) }
        }
        .configurationDisplayName("BRAVIA Remote")
        .description("Control your saved Sony BRAVIA from the Home Screen.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct RemoteWidgetEntry: TimelineEntry {
    var date = Date()
    let title: String?
    let availableCommands: Set<TVCommand>
    let powerState: TVPowerState

    init(title: String?, availableCommands: Set<TVCommand>, powerState: TVPowerState) {
        self.title = title
        self.availableCommands = availableCommands
        self.powerState = powerState
    }

    init(configuration: WidgetTVConfiguration?, powerState: TVPowerState = .unknown) {
        title = configuration?.device.displayTitle
        self.powerState = powerState
        availableCommands = Set(TVCommand.allCases.filter { command in
            guard let configuration else { return false }
            return command.irccCode(reported: configuration.remoteCommandCodes) != nil
        })
    }
}

private struct RemoteWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemoteWidgetEntry {
        RemoteWidgetEntry(title: "Sony BRAVIA", availableCommands: Set(TVCommand.allCases), powerState: .active)
    }

    func getSnapshot(in context: Context, completion: @escaping (RemoteWidgetEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : RemoteWidgetEntry(
            configuration: try? WidgetTVConfiguration.load()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RemoteWidgetEntry>) -> Void) {
        Task { @MainActor in
            guard let configuration = try? WidgetTVConfiguration.load() else {
                completion(Timeline(entries: [RemoteWidgetEntry(configuration: nil)], policy: .never))
                return
            }
            let powerState = try? await SonyTVClient().powerStatus(
                for: configuration.device,
                preSharedKey: configuration.preSharedKey
            )
            let entry = RemoteWidgetEntry(configuration: configuration, powerState: powerState ?? .unknown)
            completion(Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(15 * 60))))
        }
    }
}

private struct RemoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RemoteWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(entry.title ?? "BRAVIA Remote", systemImage: "tv")
                .font(.headline)
                .lineLimit(1)
            if entry.title == nil {
                Text("Open BRAVIA Controller to connect your TV.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                row([.power, .mute, .volumeDown, .volumeUp])
                if family == .systemLarge {
                    row([.input, .up, .options])
                    row([.left, .confirm, .right])
                    row([.back, .down, .home])
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func row(_ commands: [TVCommand]) -> some View {
        HStack(spacing: 8) {
            ForEach(commands) { command in
                if entry.availableCommands.contains(command) {
                    Button(intent: SendTVCommandIntent(command: command)) {
                        buttonFace(command)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(command.title)
                    .accessibilityValue(command == .power ? powerLabel : "")
                } else {
                    buttonFace(command)
                        .opacity(0.35)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func buttonFace(_ command: TVCommand) -> some View {
        let isPower = command == .power
        let isOn = isPower && entry.powerState == .active
        let isStandby = isPower && entry.powerState == .standby
        return VStack(spacing: 3) {
            Image(systemName: command.systemImage)
                .font(.title3.weight(.semibold))
            if isPower {
                Text(powerLabel)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(isOn ? Color.white : isStandby ? powerColor : .primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isOn ? powerColor : .primary.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var powerColor: Color {
        Color(red: 0.12, green: 0.58, blue: 0.24)
    }

    private var powerLabel: LocalizedStringKey {
        switch entry.powerState {
        case .active: "On"
        case .standby: "Standby"
        case .unknown: "Unknown"
        }
    }
}
