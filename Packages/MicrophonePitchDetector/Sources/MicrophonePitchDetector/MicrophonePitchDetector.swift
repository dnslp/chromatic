import AVFoundation
import SwiftUI
#if os(watchOS)
import WatchKit
#endif

public final class MicrophonePitchDetector: ObservableObject {
    private let engine = AudioEngine()
    public var isRunning = false // Made public to allow TunerView to check status
    private var tracker: PitchTap!

    @Published public var pitch: Double = 440
    @Published public var amplitude: Double = 0.0
    @Published public var didReceiveAudio = false
    @Published public var showMicrophoneAccessAlert = false

    public init() {}

    @MainActor
    public func start() async throws {
        guard !isRunning else { return }

        // Request permission only if not previously granted or denied
        if !showMicrophoneAccessAlert { // Avoid re-prompting if already denied
            switch await MicrophoneAccess.getOrRequestPermission() {
            case .granted:
                try await 실제로엔진을시작하는함수() // Changed "setUpPitchTracking" to a more descriptive name
            case .denied:
                showMicrophoneAccessAlert = true
                return // Do not proceed if permission is denied
            }
        } else if AVAudioSession.sharedInstance().recordPermission == .granted {
            // If alert was shown due to a previous denial, but permission has since been granted (e.g. in settings)
            showMicrophoneAccessAlert = false // Reset alert status
            try await 실제로엔진을시작하는함수()
        } else {
            // If permission is still denied, do nothing further.
            return
        }
    }

    @MainActor
    private func 실제로엔진을시작하는함수() async throws { // Renamed from setUpPitchTracking
        guard !isRunning else { return } // Ensure it's not already running

#if !os(macOS)
        // Session configuration should ideally happen once, or be idempotent.
        // If called multiple times, ensure it doesn't cause issues.
        try engine.configureSession()
#endif
        if tracker == nil { // Initialize tracker only if it hasn't been initialized
            tracker = PitchTap(engine.inputMixer, handler: { pitch, amplitude in
                Task { @MainActor in
                    self.pitch = pitch
                    self.amplitude = amplitude
                }
            }, didReceiveAudio: {
                Task { @MainActor in
                    self.didReceiveAudio = true
                }
            })
        }

        try engine.start()
        tracker.start() // Ensure tracker is started
        isRunning = true
    }

    @MainActor
    public func stop() {
        guard isRunning else { return }
        tracker?.stop() // Stop the tracker first
        engine.stop()
        isRunning = false
        // Consider whether didReceiveAudio should be reset here
        // self.didReceiveAudio = false
    }

    @MainActor
    public func restart() async throws {
        stop()
        // Adding a small delay to ensure resources are released before restarting
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try await start()
    }

    // Existing activate() function can now call start()
    // This maintains compatibility if other parts of the app use activate()
    @MainActor
    public func activate() async throws {
        try await start()
    }
}
