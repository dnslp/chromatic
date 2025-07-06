//
//  SpectogramView.swift
//  Chromatic
//
//  Created by David Nyman on 7/6/25.
//

import SwiftUI
import AudioKit

struct SpectogramView: View {
    @StateObject private var audioManager = SpectrogramAudioManager()

    var body: some View {
        Group {
            if let mixer = audioManager.mixer {
                SpectrogramFlatView(node: mixer)
            } else {
                Text("Audio engine starting...")
                    .onAppear {
                        audioManager.start()
                    }
            }
        }
        .onAppear {
            audioManager.start()
        }
        .onDisappear {
            audioManager.stop()
        }
    }
}

class SpectrogramAudioManager: ObservableObject {
    let engine = AudioEngine()
    var mixer: Mixer?
    var input: Node?

    init() {
        #if os(macOS)
        // Use default input on macOS
        input = engine.input
        #else
        // On iOS/watchOS, check for mic permission first
        // For simplicity, this example assumes permission is granted or will be handled elsewhere.
        // In a real app, you'd request permission here if needed.
        if let mic = engine.input {
            input = mic
        } else {
            print("Error: Could not get microphone input.")
            // Fallback or error handling
        }
        #endif

        if let inputNode = input {
            mixer = Mixer(inputNode)
            engine.output = mixer
        } else {
            // If no input, create a silent mixer to avoid crashing SpectrogramFlatView
            // or provide some feedback to the user.
            mixer = Mixer()
            engine.output = mixer
            print("Warning: No audio input available for Spectrogram. Using silent mixer.")
        }
    }

    func start() {
        do {
            try engine.start()
            print("Spectrogram AudioEngine Started")
        } catch {
            print("Could not start Spectrogram AudioEngine: \(error)")
        }
    }

    func stop() {
        engine.stop()
        print("Spectogram AudioEngine Stopped")
    }
}

#Preview {
    SpectogramView()
}
