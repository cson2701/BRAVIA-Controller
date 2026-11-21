import SwiftUI

struct RemoteSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hardwareVolumeControlEnabled: Bool
    let forgetTV: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use iPhone Volume Buttons", isOn: $hardwareVolumeControlEnabled)
                } header: {
                    Text("TV Volume")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When enabled, other media playback may be interrupted.")
                        Text("For the best experience, turn off Change with Buttons in iPhone Settings → Sounds & Haptics.")
                    }
                }
                Section("Television") {
                    Button("Forget TV", role: .destructive) {
                        HapticFeedback.tap()
                        dismiss()
                        forgetTV()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
