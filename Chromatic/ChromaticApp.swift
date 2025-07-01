// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player
import SwiftUI
import MicrophonePitchDetector

@main
struct ChromaticApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var pitchDetector = MicrophonePitchDetector()
    @AppStorage("modifierPreference") private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition") private var selectedTransposition = 0

    var body: some Scene {
        WindowGroup {
            TabView {
                TunerScreen(pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }
                PlayerView(audioPlayer: audioPlayer, pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tabItem { Label("Player", systemImage: "music.note") }
                FunctionGeneratorView(engine: FunctionGeneratorEngine())
                    .tabItem { Label("Func Gen", systemImage: "waveform.path") }
            }
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
        }
    }
}
