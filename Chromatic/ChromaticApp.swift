// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player
import SwiftUI
import MicrophonePitchDetector

@main
struct ChromaticApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    // @StateObject private var pitchDetector = MicrophonePitchDetector() // Removed shared instance
    @AppStorage("modifierPreference") private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition") private var selectedTransposition = 0
    @State private var selectedTab = 0 // 0: Tuner, 1: Player, 2: Spectrogram

    var body: some Scene {
        WindowGroup {
            
            TabView(selection: $selectedTab) {
                // TunerScreen now manages its own PitchDetector
                TunerScreen(modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tag(0)
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }
                // PlayerView no longer needs PitchDetector
                PlayerView(audioPlayer: audioPlayer, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tag(1)
                    .tabItem { Label("Player", systemImage: "music.note") }
                SpectogramView()
                    .tag(2)
                    .tabItem { Label("Spectrogram", systemImage: "waveform") }
//                FunctionGeneratorView(engine: FunctionGeneratorEngine())
//                    .tabItem { Label("Func Gen", systemImage: "waveform.path") }
            }
            .preferredColorScheme(.dark)
            // .onChange(of: selectedTab) ... This logic is no longer needed as TunerScreen manages its own PitchDetector
            // and SpectogramView its own audio engine. PlayerView does not use pitch detection.
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
        }
    }
}
