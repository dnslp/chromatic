import AVFoundation
import SwiftUI
#if os(watchOS)
import WatchKit
#endif

public final class MicrophonePitchDetector: ObservableObject {
    private let engine: AudioEngine
    private var isRunning = false
    private var tracker: PitchTap!

    @Published public var pitch: Double = 440
    @Published public var amplitude: Double = 0.0 // New published property
    @Published public var didReceiveAudio = false
    @Published public var showMicrophoneAccessAlert = false

    public init(engine: AudioEngine = AudioEngine()) {
        self.engine = engine
    }

    @MainActor
    public func activate() async throws {
        guard !isRunning else { return }

        switch await MicrophoneAccess.getOrRequestPermission() {
        case .granted:
            try await setUpPitchTracking()
        case .denied:
            showMicrophoneAccessAlert = true
        }
    }

    private func setUpPitchTracking() async throws {
        tracker = PitchTap(engine.inputMixer, handler: { pitch, amplitude in
            Task { @MainActor in
                self.pitch = pitch
                self.amplitude = amplitude // Set the new amplitude property
            }
        }, didReceiveAudio: {
            Task { @MainActor in
                self.didReceiveAudio = true
            }
        })

        isRunning = true
        try engine.start()
        tracker.start()
    }
}
