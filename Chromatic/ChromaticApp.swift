// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player
import SwiftUI
import MicrophonePitchDetector
import AVFoundation

@main
struct ChromaticApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    private let sharedEngine = AVAudioEngine()
    @StateObject private var pitchDetector: MicrophonePitchDetector
    private let functionGenerator: FunctionGeneratorEngine
    private let mixerEngine: MixerEngine

    init() {
        // Configure MicrophonePitchDetector with the shared engine
        let detectorEngine = AudioEngine(avAudioEngine: sharedEngine)
        _pitchDetector = StateObject(wrappedValue: MicrophonePitchDetector(engine: detectorEngine))

        // Other engines attach to the same AVAudioEngine
        functionGenerator = FunctionGeneratorEngine(engine: sharedEngine)
        mixerEngine = MixerEngine(engine: sharedEngine)
    }
    @AppStorage("modifierPreference") private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition") private var selectedTransposition = 0

    var body: some Scene {
        WindowGroup {
            TabView {
                TunerScreen(pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition).tabItem { Label("Tuner", systemImage: "tuningfork") }
                PlayerView(audioPlayer: audioPlayer, pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tabItem { Label("Player", systemImage: "music.note") }
                FunctionGeneratorView(engine: functionGenerator)
                    .tabItem { Label("Func Gen", systemImage: "waveform.path") }
            }
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
                configureAudioSession()
            }
        }
    }

    private func configureAudioSession() {
#if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        let preferredFrames: Double = 256
        let bufferDuration = preferredFrames / 44_100
#if !os(watchOS)
        try? session.setPreferredIOBufferDuration(bufferDuration)
        try? session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
#endif
        try? session.setActive(true)
#endif
        // Ensure the pitch detector's input is attached before starting
        pitchDetector.prepareInput()
        do {
            try sharedEngine.start()
        } catch {
            print("❌ Shared engine failed to start: \(error)")
        }
    }
}
