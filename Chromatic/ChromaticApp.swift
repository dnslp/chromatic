// ChromaticApp.swift
// Your @main entry, now hosting both tuner and player

import SwiftUI

@main
struct ChromaticApp: App {
    // Single shared player instance
    @StateObject private var audioPlayer = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            TabView {
                // Tuner tab
                TunerScreen()
                    .tabItem {
                        Label("Tuner", systemImage: "tuningfork")
                    }

                // Player tab
                PlayerView(audioPlayer: audioPlayer)
                    .tabItem {
                        Label("Player", systemImage: "music.note")
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
