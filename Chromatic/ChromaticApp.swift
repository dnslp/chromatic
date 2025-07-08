// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player
import SwiftUI
import MicrophonePitchDetector
import AudioKit

@main
struct ChromaticApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var pitchDetector = MicrophonePitchDetector()
    @StateObject private var sessionStore = SessionStore() // Initialize SessionStore
    @AppStorage("modifierPreference") private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition") private var selectedTransposition = 0
    

    var body: some Scene {
        WindowGroup {
            
            TabView {
                TunerScreen(pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }

                PlayerView(audioPlayer: audioPlayer, pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tabItem { Label("Player", systemImage: "music.note") }

                SavedSessionsView() // Add SavedSessionsView as a new tab
                    .tabItem { Label("Sessions", systemImage: "list.bullet.rectangle") }

//                FunctionGeneratorView(engine: FunctionGeneratorEngine())
//                    .tabItem { Label("Func Gen", systemImage: "waveform.path") }
//                SpectogramView().tabItem { Label("Spectrum", systemImage: "waveform") }
            }
            .environmentObject(sessionStore) // Inject SessionStore into the environment
            .preferredColorScheme(.dark)
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    // Attempt to start the pitch detector when app becomes active
                    // The `start()` method in MicrophonePitchDetector should handle permissions
                    // and not start if already running.
                    // We'll rely on TunerView's state to decide if it *should* be active.
                    // For now, ChromaticApp will always try to start it, and TunerView can pause it.
                    Task {
                        try? await pitchDetector.start()
                    }
                } else if newPhase == .inactive {
                    // Potentially stop here if we want to be aggressive about releasing resources
                    // when app is merely inactive (e.g. app switcher showing)
                    // For now, only stopping on .background
                } else if newPhase == .background {
                    // Stop the pitch detector when app goes to background
                    pitchDetector.stop()
                }
            }
        }
    }
}
