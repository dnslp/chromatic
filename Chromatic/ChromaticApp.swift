// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player
import SwiftUI
import MicrophonePitchDetector // Ensure this import is present

@main
struct ChromaticApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var pitchDetector = MicrophonePitchDetector() // Create the shared instance

    var body: some Scene {
        WindowGroup {
            TabView {
                TunerScreen(pitchDetector: pitchDetector) // Pass the detector
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }
                PlayerView(audioPlayer: audioPlayer, pitchDetector: pitchDetector) // Pass the detector
                    .tabItem { Label("Player", systemImage: "music.note") }
                FunctionGeneratorView(engine: FunctionGeneratorEngine(), pitchDetector: pitchDetector) // Pass the detector
                    .tabItem { Label("Func Gen", systemImage: "waveform.path") }
            }
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
            // It's good practice to manage the lifecycle of the pitch detector
            // if it needs explicit starting/stopping beyond its internal .task in TunerScreen.
            // For now, TunerScreen's .task will handle activation when that tab appears.
            // If other tabs need it active even if TunerScreen hasn't appeared yet,
            // we might need to move the .task here or ensure it's activated appropriately.
        }
    }
}
