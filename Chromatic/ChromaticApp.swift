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
    @StateObject private var profileManager = UserProfileManager()
    @AppStorage("modifierPreference") private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition") private var selectedTransposition = 0
    

    var body: some Scene {
        WindowGroup {
            
            TabView {
                TunerScreen(pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }

                PlayerView(audioPlayer: audioPlayer, pitchDetector: pitchDetector, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
                    .tabItem { Label("Player", systemImage: "music.note") }

                ProfilesTabView()
                    .tabItem { Label("Profiles", systemImage: "person.crop.circle") }

                SavedSessionsView() // Add SavedSessionsView as a new tab
                    .tabItem { Label("Sessions", systemImage: "list.bullet.rectangle") }

//                FunctionGeneratorView(engine: FunctionGeneratorEngine())
//                    .tabItem { Label("Func Gen", systemImage: "waveform.path") }
//                SpectogramView().tabItem { Label("Spectrum", systemImage: "waveform") }
            }
            .environmentObject(sessionStore) // Inject SessionStore into the environment
            .environmentObject(profileManager)
            .preferredColorScheme(.dark)
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
        }
    }
}
