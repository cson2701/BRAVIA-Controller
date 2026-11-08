import SwiftUI

struct SetupView: View {
    @ObservedObject var appModel: AppModel
    @State private var host = ""
    @State private var port = 80
    @State private var selectedTV: DiscoveredTV?
    @State private var preSharedKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Connect to your Sony BRAVIA over the same local network.", systemImage: "tv")
                }

                Section("TV settings") {
                    Text("Enable IP control, choose Pre-Shared Key authentication, and enable Remote Start if you want to wake the TV.")
                        .foregroundStyle(.secondary)
                }

                Section("Nearby TVs") {
                    if appModel.isDiscovering {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Looking for BRAVIA TVs…")
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(appModel.discoveredTVs) { tv in
                        Button {
                            HapticFeedback.tap()
                            selectedTV = tv
                            host = tv.host
                            port = tv.port
                        } label: {
                            HStack {
                                Image(systemName: "tv")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tv.displayTitle)
                                        .foregroundStyle(.primary)
                                    Text(tv.host)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedTV?.id == tv.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }

                    if let message = appModel.discoveryMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        HapticFeedback.tap()
                        Task { await appModel.discoverTVs() }
                    } label: {
                        Label("Scan Again", systemImage: "arrow.clockwise")
                    }
                    .disabled(appModel.isDiscovering)
                }

                Section("Connection") {
                    TextField(
                        "TV IP address",
                        text: Binding(
                            get: { host },
                            set: {
                                host = $0
                                port = 80
                                selectedTV = nil
                            }
                        ),
                        prompt: Text("192.168.1.100")
                    )
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Pre-shared key", text: $preSharedKey)
                }

                Section {
                    Button {
                        HapticFeedback.tap()
                        Task {
                            await appModel.connect(
                                host: host,
                                port: port,
                                preSharedKey: preSharedKey
                            )
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if appModel.connectionState == .connecting {
                                ProgressView()
                            } else {
                                Text("Test and Save TV")
                            }
                            Spacer()
                        }
                    }
                    .disabled(host.isEmpty || preSharedKey.isEmpty || appModel.connectionState == .connecting)
                }
            }
            .navigationTitle("Set Up BRAVIA")
            .task {
                if appModel.discoveredTVs.isEmpty {
                    await appModel.discoverTVs()
                }
            }
        }
    }
}
