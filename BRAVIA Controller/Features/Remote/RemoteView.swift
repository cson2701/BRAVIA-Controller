import SwiftUI

struct RemoteView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    connectionHeader

                    HStack {
                        commandButton(.power, prominent: true)
                            .tint(.red)
                        commandButton(.input)
                    }

                    HStack {
                        commandButton(.back)
                        commandButton(.home)
                        commandButton(.options)
                    }

                    DirectionPad(send: send)

                    HStack(spacing: 20) {
                        verticalControl(title: "Volume", upper: .volumeUp, lower: .volumeDown)
                        commandButton(.mute)
                        verticalControl(title: "Channel", upper: .channelUp, lower: .channelDown)
                    }

                    HStack {
                        commandButton(.previous)
                        commandButton(.play)
                        commandButton(.pause)
                        commandButton(.next)
                    }
                }
                .padding()
            }
            .navigationTitle(appModel.device?.name ?? "BRAVIA Remote")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reconnect") {
                            Task { await appModel.reconnect() }
                        }
                        Button("Forget TV", role: .destructive) {
                            appModel.forgetDevice()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await appModel.reconnect()
            }
        }
    }

    private var connectionHeader: some View {
        HStack {
            Circle()
                .fill(appModel.connectionState == .connected ? .green : .orange)
                .frame(width: 9, height: 9)
            Text(appModel.connectionState.label)
            Spacer()
            Text(appModel.powerState.rawValue.capitalized)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func verticalControl(title: String, upper: TVCommand, lower: TVCommand) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            commandButton(upper)
            commandButton(lower)
        }
    }

    private func commandButton(_ command: TVCommand, prominent: Bool = false) -> some View {
        RemoteCommandButton(command: command, prominent: prominent) {
            send(command)
        }
    }

    private func send(_ command: TVCommand) {
        Task { await appModel.send(command) }
    }
}
