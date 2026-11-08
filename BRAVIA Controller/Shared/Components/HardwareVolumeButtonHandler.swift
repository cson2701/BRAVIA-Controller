import AVFAudio
import MediaPlayer
import SwiftUI

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
        coordinator.disable()
    }

    @MainActor
    final class Coordinator: NSObject {
        private static let neutralVolume: Float = 0.5
        private static let volumeTolerance: Float = 0.001

        private let audioSession = AVAudioSession.sharedInstance()
        private var volumeObservation: NSKeyValueObservation?
        private weak var volumeSlider: UISlider?
        private var originalSystemVolume: Float?
        private var originalAudioCategory: AVAudioSession.Category?
        private var originalAudioMode: AVAudioSession.Mode?
        private var originalAudioCategoryOptions: AVAudioSession.CategoryOptions?
        private var didActivateAudioSession = false
        private var requestedEnabled = false
        private var activationGeneration = 0
        private var onVolumeUp: () -> Void
        private var onVolumeDown: () -> Void

        init(onVolumeUp: @escaping () -> Void, onVolumeDown: @escaping () -> Void) {
            self.onVolumeUp = onVolumeUp
            self.onVolumeDown = onVolumeDown
        }

        func update(
            volumeView: MPVolumeView,
            isEnabled: Bool,
            onVolumeUp: @escaping () -> Void,
            onVolumeDown: @escaping () -> Void
        ) {
            self.onVolumeUp = onVolumeUp
            self.onVolumeDown = onVolumeDown

            guard isEnabled != requestedEnabled else { return }
            requestedEnabled = isEnabled
            activationGeneration += 1

            if isEnabled {
                let generation = activationGeneration
                DispatchQueue.main.async { [weak self, weak volumeView] in
                    guard let self,
                          let volumeView,
                          self.requestedEnabled,
                          self.activationGeneration == generation else { return }
                    self.enable(using: volumeView)
                }
            } else {
                disable()
            }
        }

        func disable() {
            requestedEnabled = false
            activationGeneration += 1
            volumeObservation?.invalidate()
            volumeObservation = nil

            if let originalSystemVolume {
                setSystemVolume(originalSystemVolume)
            }

            if didActivateAudioSession {
                try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                didActivateAudioSession = false
            }
            restoreAudioSessionConfiguration()
            originalSystemVolume = nil
            volumeSlider = nil
        }

        private func enable(using volumeView: MPVolumeView) {
#if !targetEnvironment(simulator)
            // MPVolumeView controls the volume of the active media route. When
            // AirPlay is connected that route is the TV, so moving the slider
            // to the neutral capture point would immediately set the TV to 50%.
            // Leave hardware volume handling to the system while AirPlay is in
            // use instead of intercepting those button presses for IRCC.
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
                // An active playback-capable session makes the rocker adjust
                // media volume instead of the phone's ringer volume. Ambient
                // preserves audio playing in other apps.
                try audioSession.setCategory(.ambient, mode: .default)
                try audioSession.setActive(true)
                didActivateAudioSession = true
            } catch {
                restoreAudioSessionConfiguration()
                volumeSlider = nil
                return
            }

            originalSystemVolume = audioSession.outputVolume
            setSystemVolume(Self.neutralVolume)

            volumeObservation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
                guard let newVolume = change.newValue else { return }
                Task { @MainActor [weak self] in
                    self?.systemVolumeDidChange(to: newVolume)
                }
            }
#endif
        }

        private func systemVolumeDidChange(to newVolume: Float) {
            guard requestedEnabled,
                  abs(newVolume - Self.neutralVolume) > Self.volumeTolerance else {
                return
            }

            if newVolume > Self.neutralVolume {
                onVolumeUp()
            } else {
                onVolumeDown()
            }

            setSystemVolume(Self.neutralVolume)
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
