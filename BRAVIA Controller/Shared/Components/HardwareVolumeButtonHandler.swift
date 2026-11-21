import AVFAudio
import MediaPlayer
import OSLog
import SwiftUI
import UIKit

/// Converts physical volume-button presses into app actions while enabled.
///
/// iOS doesn't expose volume-button events directly for non-camera apps. An
/// `MPVolumeView` keeps the system volume control in the view hierarchy, while
/// observing `AVAudioSession.outputVolume` reveals which button was pressed.
struct HardwareVolumeButtonHandler: UIViewRepresentable {
    let isEnabled: Bool
    let onVolumeUp: () -> Void
    let onVolumeDown: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onVolumeUp: onVolumeUp, onVolumeDown: onVolumeDown)
    }

    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.alpha = 0.001
        return volumeView
    }

    func updateUIView(_ volumeView: MPVolumeView, context: Context) {
        context.coordinator.update(
            volumeView: volumeView,
            isEnabled: isEnabled,
            onVolumeUp: onVolumeUp,
            onVolumeDown: onVolumeDown
        )
    }

    static func dismantleUIView(_ volumeView: MPVolumeView, coordinator: Coordinator) {
        coordinator.detach()
    }

    @MainActor
    final class Coordinator: NSObject {
        private static let foregroundVolume: Float = 0.30
        private static let volumeTolerance: Float = 0.001
        private static let logger = Logger(subsystem: "scrapps.BRAVIA-Controller", category: "HardwareVolume")

        private let audioSession = AVAudioSession.sharedInstance()
        private var volumeObservation: NSKeyValueObservation?
        private weak var volumeView: MPVolumeView?
        private weak var volumeSlider: UISlider?
        private var originalSystemVolume: Float?
        private var baselineVolume: Float?
        private var volumeRoute: [String]?
        private var startupTask: Task<Void, Never>?
        private var restorationTask: Task<Void, Never>?
        private var restorationBackgroundTask: UIBackgroundTaskIdentifier = .invalid
        private var originalAudioCategory: AVAudioSession.Category?
        private var originalAudioMode: AVAudioSession.Mode?
        private var originalAudioCategoryOptions: AVAudioSession.CategoryOptions?
        private var didActivateAudioSession = false
        private var isEnabled = false
        private var requestedEnabled = false
        private var activationGeneration = 0
        private var onVolumeUp: () -> Void
        private var onVolumeDown: () -> Void

        init(onVolumeUp: @escaping () -> Void, onVolumeDown: @escaping () -> Void) {
            self.onVolumeUp = onVolumeUp
            self.onVolumeDown = onVolumeDown
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationWillResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(activateIfNeeded),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }

        func update(
            volumeView: MPVolumeView,
            isEnabled: Bool,
            onVolumeUp: @escaping () -> Void,
            onVolumeDown: @escaping () -> Void
        ) {
            self.onVolumeUp = onVolumeUp
            self.onVolumeDown = onVolumeDown
            self.volumeView = volumeView
            let wasEnabled = self.isEnabled
            self.isEnabled = isEnabled
            if isEnabled {
                activateIfNeeded()
            } else if wasEnabled {
                disable()
            }
        }

        @objc private func activateIfNeeded() {
            guard isEnabled, !requestedEnabled, let volumeView,
                  UIApplication.shared.applicationState == .active else { return }
            requestedEnabled = true
            activationGeneration += 1
            let generation = activationGeneration

            Task { @MainActor [weak self, weak volumeView] in
                await self?.restorationTask?.value
                guard let self, let volumeView,
                      self.activationGeneration == generation else { return }
                guard UIApplication.shared.applicationState == .active else {
                    self.requestedEnabled = false
                    return
                }
                self.enable(using: volumeView)
            }
        }

        func detach() {
            volumeView = nil
            disable()
        }

        @objc private func applicationWillResignActive() {
            disable()
        }

        private func disable() {
            requestedEnabled = false
            activationGeneration += 1
            startupTask?.cancel()
            startupTask = nil
            volumeObservation?.invalidate()
            volumeObservation = nil

            guard restorationTask == nil else { return }
            guard let originalSystemVolume, let slider = volumeSlider,
                  currentVolumeRoute == volumeRoute else {
                finishAudioSession()
                return
            }

            // Issue the restore while the app still has focus and owns the audio session.
            restorationBackgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Restore media volume") { [weak self] in
                self?.restorationTask?.cancel()
                self?.finishAudioSession()
            }
            setSystemVolume(originalSystemVolume)
            restorationTask = Task { @MainActor in
                // MPVolumeView applies volume asynchronously. Keep the slider and session
                // alive until the change is visible, with one bounded retry.
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                if currentVolumeRoute == volumeRoute,
                   abs(audioSession.outputVolume - originalSystemVolume) > Self.volumeTolerance {
                    slider.value = originalSystemVolume
                    slider.sendActions(for: .valueChanged)
                    try? await Task.sleep(for: .milliseconds(150))
                    guard !Task.isCancelled else { return }
                    if currentVolumeRoute == volumeRoute,
                       abs(audioSession.outputVolume - originalSystemVolume) > Self.volumeTolerance {
                        Self.logger.warning("iOS did not confirm the original media volume was restored.")
                    }
                }
                finishAudioSession()
            }
        }

        private func finishAudioSession() {
            if didActivateAudioSession {
                try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                didActivateAudioSession = false
            }
            restoreAudioSessionConfiguration()
            originalSystemVolume = nil
            baselineVolume = nil
            volumeRoute = nil
            volumeSlider = nil
            restorationTask = nil
            if restorationBackgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(restorationBackgroundTask)
                restorationBackgroundTask = .invalid
            }
        }

        private func enable(using volumeView: MPVolumeView) {
#if !targetEnvironment(simulator)
            // AirPlay already sends volume changes to the active media route.
            guard !audioSession.currentRoute.outputs.contains(where: { $0.portType == .airPlay }),
                  volumeObservation == nil,
                  let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else {
                return
            }

            volumeSlider = slider
            originalAudioCategory = audioSession.category
            originalAudioMode = audioSession.mode
            originalAudioCategoryOptions = audioSession.categoryOptions
            do {
                // A nonmixable session lets iOS interrupt existing media playback.
                try audioSession.setCategory(.playback, mode: .default)
                try audioSession.setActive(true)
                didActivateAudioSession = true
            } catch {
                restoreAudioSessionConfiguration()
                volumeSlider = nil
                return
            }

            let generation = activationGeneration
            startupTask = Task { [weak self] in
                // Give the newly active session time to report the current route and volume.
                try? await Task.sleep(for: .milliseconds(150))
                guard let self, !Task.isCancelled, self.activationGeneration == generation,
                      UIApplication.shared.applicationState == .active else { return }
                guard !self.audioSession.currentRoute.outputs.contains(where: { $0.portType == .airPlay }) else {
                    self.disable()
                    return
                }

                self.volumeRoute = self.currentVolumeRoute
                self.originalSystemVolume = self.audioSession.outputVolume
                self.setSystemVolume(Self.foregroundVolume)

                // Let the route apply and round the requested volume before observing it.
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled, self.activationGeneration == generation,
                      self.currentVolumeRoute == self.volumeRoute else { return }
                self.observeVolume(baseline: self.audioSession.outputVolume, generation: generation)
            }
#endif
        }

        private var currentVolumeRoute: [String] {
            audioSession.currentRoute.outputs.map(\.uid)
        }

        private func observeVolume(baseline: Float, generation: Int) {
            baselineVolume = baseline
            volumeObservation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
                guard let newVolume = change.newValue else { return }
                Task { @MainActor [weak self] in
                    guard let self, self.activationGeneration == generation else { return }
                    self.systemVolumeDidChange(to: newVolume)
                }
            }
        }

        private func systemVolumeDidChange(to newVolume: Float) {
            guard requestedEnabled,
                  currentVolumeRoute == volumeRoute,
                  let baselineVolume,
                  abs(newVolume - baselineVolume) > Self.volumeTolerance else {
                return
            }

            if newVolume > baselineVolume {
                onVolumeUp()
            } else {
                onVolumeDown()
            }

            setSystemVolume(baselineVolume)
        }

        private func setSystemVolume(_ volume: Float) {
            guard let volumeSlider else { return }
            volumeSlider.value = volume
            volumeSlider.sendActions(for: .valueChanged)
        }

        private func restoreAudioSessionConfiguration() {
            guard let originalAudioCategory,
                  let originalAudioMode,
                  let originalAudioCategoryOptions else { return }

            try? audioSession.setCategory(
                originalAudioCategory,
                mode: originalAudioMode,
                options: originalAudioCategoryOptions
            )
            self.originalAudioCategory = nil
            self.originalAudioMode = nil
            self.originalAudioCategoryOptions = nil
        }
    }
}
