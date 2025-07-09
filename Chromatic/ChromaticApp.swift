// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player
import SwiftUI
import MicrophonePitchDetector
import AudioKit

@main
struct ChromaticApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var pitchDetector = MicrophonePitchDetector()
    @State private var tunerData = TunerData() // Added state for TunerData
    @StateObject private var sessionStore = SessionStore() // Initialize SessionStore
    @StateObject private var profileManager = UserProfileManager() // Initialize UserProfileManager
    @AppStorage("modifierPreference") private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition") private var selectedTransposition = 0
    

    var body: some Scene {
        WindowGroup {
            
            TabView {
                TunerView(tunerData: $tunerData, modifierPreference: $modifierPreference, selectedTransposition: $selectedTransposition)
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
            .environmentObject(profileManager) // Inject UserProfileManager into the environment
            .preferredColorScheme(.dark)
            .onReceive(pitchDetector.$pitch) { newPitch in
                self.tunerData = TunerData(pitch: newPitch, amplitude: self.tunerData.amplitude, harmonics: self.tunerData.harmonics)
            }
            .onReceive(pitchDetector.$amplitude) { newAmplitude in
                self.tunerData = TunerData(pitch: self.tunerData.pitch.hertz, amplitude: newAmplitude, harmonics: self.tunerData.harmonics)
            }
            .onAppear {
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
        }
    }
}
