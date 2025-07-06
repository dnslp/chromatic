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
    @State private var selectedTab = 0 // 0: Tuner, 1: Player, 2: Spectrogram

    var body: some Scene {
        WindowGroup {
            
            TabView(selection: $selectedTab) {
                TunerScreen(pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tag(0)
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }
                PlayerView(audioPlayer: audioPlayer, pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tag(1)
                    .tabItem { Label("Player", systemImage: "music.note") }
                SpectogramView(pitchDetector: pitchDetector)
                    .tag(2)
                    .tabItem { Label("Spectrogram", systemImage: "waveform") }
//                FunctionGeneratorView(engine: FunctionGeneratorEngine())
//                    .tabItem { Label("Func Gen", systemImage: "waveform.path") }
            }
            .preferredColorScheme(.dark)
            .onChange(of: selectedTab) { newTab in
                Task {
                    if newTab == 0 || newTab == 2 { // Tuner or Spectrogram
                        try? await pitchDetector.activate()
                    } else {
                        await pitchDetector.deactivate()
                    }
                }
            }
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
        }
    }
}
