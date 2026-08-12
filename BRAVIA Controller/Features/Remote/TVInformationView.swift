import SwiftUI

struct TVInformationView: View {
    @ObservedObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var hasInitializedNickname = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Nickname") {
                    TextField(
                        "Nickname",
                        text: $title,
                        prompt: Text(appModel.device?.model ?? "TV nickname")
                    )
                        .textInputAutocapitalization(.words)
                        .onChange(of: title) { _, newValue in
                            guard hasInitializedNickname else { return }
                            appModel.renameDevice(newValue)
                        }

                    if appModel.device?.customTitle != nil {
                        Button("Use Model Number") {
                            HapticFeedback.tap()
                            title = ""
                        }
                    }
                }

                Section("Connection") {
                    informationRow("IP Address", value: appModel.device?.host)
                    informationRow("Port", value: appModel.device.map { String($0.port) })
                }

                Section("Television") {
                    informationRow("Name", value: appModel.systemInformation?.name ?? appModel.device?.name)
                    informationRow("Model", value: appModel.systemInformation?.model ?? appModel.device?.model)
                    informationRow("Product", value: appModel.systemInformation?.product)
                    informationRow("Serial Number", value: appModel.systemInformation?.serial)
                    informationRow("MAC Address", value: appModel.systemInformation?.macAddr)
                    informationRow("API Generation", value: appModel.systemInformation?.generation)
                    informationRow("Region", value: appModel.systemInformation?.region)
                    informationRow("Area", value: appModel.systemInformation?.area)
                    informationRow("Language", value: appModel.systemInformation?.language)
                }
            }
            .navigationTitle("TV Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if appModel.isLoadingSystemInformation {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        HapticFeedback.tap()
                        dismiss()
                    }
                }
            }
            .task {
                await appModel.refreshSystemInformation()
            }
            .onAppear {
                title = appModel.device?.customTitle ?? ""
                hasInitializedNickname = true
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func informationRow(_ label: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            LabeledContent(label, value: value)
        }
    }
}
