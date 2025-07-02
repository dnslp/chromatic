import AVFoundation
import SwiftUI
#if os(watchOS)
import WatchKit
#endif

// Assuming MicrophoneState enum is defined in the same module or imported
// If Chromatic/Models/MicrophoneState.swift is in a different module,
// you'll need to ensure it's accessible here, possibly by moving it
// or adjusting project settings. For now, I'll assume it's available.
// If not, we might need to define it here or make it part of this package.
// Removed placeholder for MicrophoneState.
// Assuming 'import Chromatic' or similar makes MicrophoneState available,
// or that MicrophoneState.swift is part of this target/package.
// If MicrophoneState is in the main app target "Chromatic",
// and this is a package, direct import might not work without
// making MicrophoneState public and the module "Chromatic" importable,
// or by moving MicrophoneState into this package or a shared package.
// For now, proceeding as if it's resolvable by the build system.

public final class MicrophonePitchDetector: ObservableObject {
    private let engine = AudioEngine() // AVAudioEngine wrapper
    private var isAudioSessionConfigured = false // Track if session is configured
    private var audioEngineStarted = false // Tracks if the AVAudioEngine itself is running
    private var pitchTrackerStarted = false // Tracks if the PitchTap is active

    @Published public var pitch: Double = 440
    @Published public var amplitude: Double = 0.0
    @Published public var didReceiveAudio = false
    @Published public var showMicrophoneAccessAlert = false
    @Published public var microphoneState: MicrophoneState = .on

    public init() {}

    @MainActor
    private func ensureAudioSessionIsConfiguredAndActive() async throws {
        if await MicrophoneAccess.getOrRequestPermission() == .denied {
            showMicrophoneAccessAlert = true
            throw NSError(domain: "MicrophonePitchDetector", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."])
        }

        #if !os(macOS)
        // Configure the audio session if it hasn't been, or if it was deactivated.
        // AVAudioSession setup is typically done once.
        // If the engine stops and session deactivates, it might need reactivation.
        if !isAudioSessionConfigured {
            try engine.configureSession() // Assumes this sets category and activates.
            isAudioSessionConfigured = true
        } else {
            // If already configured, ensure it's still active, especially if resuming.
            // This part is tricky; `configureSession` might handle reactivation.
            // Or, we might need an explicit `engine.activateSession()` if it was deactivated.
            // For now, assume `configureSession` is safe to call if needed or handles it.
        }
        #endif
    }

    @MainActor
    public func activate() async throws {
        // This function is the main entry point to start using the detector.
        // It ensures permissions, configures audio session, and applies the initial microphone state.
        try await ensureAudioSessionIsConfiguredAndActive()
        try await setMicrophoneState(microphoneState, forceApply: true)
    }

    @MainActor
    private func startAudioEngineIfNeeded() async throws {
        // Ensure session is configured before starting engine.
        try await ensureAudioSessionIsConfiguredAndActive()
        if !audioEngineStarted {
            try engine.start()
            audioEngineStarted = true
        }
    }

    @MainActor
    private func stopAudioEngine() {
        // Stops the audio engine and marks the session as not necessarily configured for next use.
        // This is a more definitive stop.
        if audioEngineStarted {
            engine.stop()
            audioEngineStarted = false
            // Consider deactivating audio session here if appropriate, e.g., engine.deactivateSession()
            // isAudioSessionConfigured = false; // If session is deactivated.
            // For now, assume stopping engine doesn't deactivate session,
            // but this is a point for deeper AVFoundation knowledge.
        }
    }

    @MainActor
    private func startPitchTracker() async throws {
        // Ensure engine is running before attaching tap. This also handles session configuration.
        try await startAudioEngineIfNeeded()

        if !pitchTrackerStarted {
            if tracker == nil {
                tracker = PitchTap(engine.inputMixer, handler: { [weak self] pitch, amplitude in
                    guard let self = self, self.pitchTrackerStarted else { return }
                    Task { @MainActor in
                        self.pitch = pitch
                        self.amplitude = amplitude
                    }
                }, didReceiveAudio: { [weak self] in
                    Task { @MainActor in
                        self?.didReceiveAudio = true
                    }
                })
            }
            tracker.start()
            pitchTrackerStarted = true
        }
    }

    @MainActor
    private func stopPitchTracker() {
        if pitchTrackerStarted {
            tracker?.stop()
            pitchTrackerStarted = false
        }
    }

    @MainActor
    public func setMicrophoneState(_ newState: MicrophoneState, forceApply: Bool = false) async throws {
        if newState == microphoneState && !forceApply { return }

        // Ensure audio session is configured and permissions are granted before proceeding,
        // especially if moving to a state that uses the microphone.
        if newState != .muted {
            try await ensureAudioSessionIsConfiguredAndActive()
        }

        let oldState = microphoneState
        microphoneState = newState

        // Consider using objectWillChange.send() if @Published doesn't update complex dependent UI immediately.
        // For simple state changes, @Published is usually sufficient.

        switch microphoneState {
        case .on:
            try await startPitchTracker()
        case .muted:
            stopPitchTracker()
            // For a full mute, we should stop the engine to release the microphone completely.
            // This helps with system resources and privacy indicators.
            stopAudioEngine() // More definitive stop
        case .pushToTalk:
            stopPitchTracker() // Stop tracker by default, PTT button will toggle it.
            // Ensure engine is running and session is active for PTT readiness.
            try await startAudioEngineIfNeeded()
        }
    }

    @MainActor
    public func togglePushToTalk(isPressed: Bool) async throws {
        guard microphoneState == .pushToTalk else { return }

        if isPressed {
            // Ensure audio session is active and engine is started before tracking pitch.
            try await startPitchTracker()
        } else {
            stopPitchTracker()
            // Consider if engine should be stopped if PTT is released and no other mic activity is expected.
            // For now, keep engine running as PTT might be pressed again soon.
        }
    }

    @MainActor
    public func suspend() {
        // App is going to background or becoming inactive.
        let wasTracking = pitchTrackerStarted

        stopPitchTracker() // Always stop the tap.

        if wasTracking || microphoneState != .muted {
            // If we were actively using the mic (tracking or in 'on'/'PTT' state),
            // or if the engine was running for PTT readiness, stop the engine.
            stopAudioEngine()
            // Optionally, mark session as not configured if `stopAudioEngine` deactivates it.
            // isAudioSessionConfigured = false;
        }
        // If state was .muted and engine was already stopped, this does little, which is fine.
    }

    @MainActor
    public func resume() async throws {
        // App is returning to foreground.
        // Re-apply the current state, which will also handle re-activating session and engine if needed.
        // `setMicrophoneState` calls `ensureAudioSessionIsConfiguredAndActive` for non-muted states.
        try await setMicrophoneState(microphoneState, forceApply: true)
    }
}
