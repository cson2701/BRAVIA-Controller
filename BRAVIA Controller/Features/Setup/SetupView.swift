import SwiftUI

struct SetupView: View {
    @ObservedObject var appModel: AppModel
    @State private var host = ""
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

                Section("Connection") {
                    TextField("TV IP address", text: $host, prompt: Text("192.168.1.100"))
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Pre-shared key", text: $preSharedKey)
                }

                Section {
                    Button {
                        HapticFeedback.tap()
                        Task {
                            await appModel.connect(host: host, preSharedKey: preSharedKey)
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
        }
    }
}
