import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject private var pitchDetector = MicrophonePitchDetector()
    @AppStorage("modifierPreference")
    private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition")
    private var selectedTransposition = 0

    @StateObject private var playlistManager = PlaylistManager() // Instantiate PlaylistManager

    var body: some View {
        TunerView(
            tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude), // Pass amplitude
            modifierPreference: modifierPreference,
            selectedTransposition: selectedTransposition
        )
        // Pass the playlistManager to TunerView if it needs to control playback
        // For now, assuming TunerView doesn't directly control PlaylistManager,
        // but PlayerView (which might be a subview or sibling) will.
        // .environmentObject(playlistManager) // Optionally provide it to the environment
        .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5)
        .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
        .task {
            do {
                try await pitchDetector.activate()
                // Once pitchDetector is active, its engine is running.
                // Attach PlaylistManager to this engine.
                playlistManager.attachTo(engine: pitchDetector.avAudioEngine)

                // For testing, let's try playing a couple of files synchronously.
                // This part should eventually be triggered by UI interaction.
                // Ensure you have these files in your "Chromatic/Models/Audio/" directory
                // and they are included in the app bundle.
                if let url1 = Bundle.main.url(forResource: "A2-110Hz-60BPM", withExtension: "mp3", subdirectory: "Chromatic/Models/Audio"),
                   let url2 = Bundle.main.url(forResource: "C3-130.81Hz-60BPM", withExtension: "mp3", subdirectory: "Chromatic/Models/Audio") {
                    // playlistManager.playSynchronously(urls: [url1, url2])
                    // For now, let's just prepare a single track to ensure single playback still works as expected
                    // The actual synchronous play will be triggered by UI later.
                     playlistManager.play() // Example: play the initially prepared track
                } else {
                    // Try alternative paths if the above subdirectory isn't found
                    if let url1Alt = Bundle.main.url(forResource: "A2-110Hz-60BPM", withExtension: "mp3", subdirectory: "Audio"),
                       let url2Alt = Bundle.main.url(forResource: "C3-130.81Hz-60BPM", withExtension: "mp3", subdirectory: "Audio") {
                        // playlistManager.playSynchronously(urls: [url1Alt, url2Alt])
                        playlistManager.play()
                    } else {
                        print("TunerScreen: Could not find test audio files for PlaylistManager.")
                    }
                }

            } catch {
                // TODO: Handle error
                print("Error activating pitch detector or setting up playlist manager: \(error)")
            }
        }
        .alert(isPresented: $pitchDetector.showMicrophoneAccessAlert) {
            MicrophoneAccessAlert()
        }
        // Add PlayerView to the UI and pass the playlistManager
        VStack {
            Spacer() // Pushes TunerView towards the top if desired, or remove for center
            TunerView(
                tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude),
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
            // The opacity and animation modifiers were here, moved them to the parent VStack or keep per view

            PlayerView()
                .environmentObject(playlistManager) // Pass the PlaylistManager to PlayerView
                .padding(.bottom) // Add some padding at the bottom
        }
        // Moved opacity and animation to the VStack to cover both views,
        // or apply individually if different behavior is needed.
        .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5)
        .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
    }
}

struct TunerScreen_Previews: PreviewProvider {
    static var previews: some View {
        TunerScreen()
    }
}
