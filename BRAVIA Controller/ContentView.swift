//
//  ContentView.swift
//  BRAVIA Controller
//
//  Created by Chaoran Song on 12/8/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hardwareVolumeControlEnabled") private var hardwareVolumeControlEnabled = false
    @StateObject private var appModel = AppModel()

    var body: some View {
        Group {
            if appModel.device == nil {
                SetupView(appModel: appModel)
            } else {
                RemoteView(appModel: appModel, hardwareVolumeControlEnabled: $hardwareVolumeControlEnabled)
            }
        }
        .background(alignment: .topLeading) {
            HardwareVolumeButtonHandler(
                isEnabled: hardwareVolumeControlEnabled,
                onVolumeUp: { sendHardwareVolumeCommand(.volumeUp) },
                onVolumeDown: { sendHardwareVolumeCommand(.volumeDown) }
            )
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .task {
            await appModel.reconnect()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await appModel.refreshStatus() }
        }
        .alert(
            "BRAVIA Controller",
            isPresented: Binding(
                get: { appModel.presentedError != nil },
                set: { if !$0 { appModel.presentedError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                HapticFeedback.tap()
                appModel.presentedError = nil
            }
        } message: {
            Text(appModel.presentedError ?? "Unknown error")
        }
    }

    private func sendHardwareVolumeCommand(_ command: TVCommand) {
        guard appModel.connectionState == .connected, appModel.supports(command) else { return }
        HapticFeedback.repeatTick()
        Task { await appModel.send(command) }
    }
}
