// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player
import SwiftUI

@main
struct ChromaticApp: App {
    @StateObject private var audioPlayer = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            TabView {
                TunerScreen()
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }
                PlayerView(audioPlayer: audioPlayer)
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
