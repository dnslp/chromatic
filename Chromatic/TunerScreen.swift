import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject private var pitchDetector = MicrophonePitchDetector()
    @StateObject private var playlistManager = PlaylistManager() // Instantiate PlaylistManager
    @AppStorage("modifierPreference")
    private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition")
    private var selectedTransposition = 0

    var body: some View {
        TunerView(
            tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude, playlistManager: playlistManager), // Pass amplitude and playlistManager
            modifierPreference: modifierPreference,
            selectedTransposition: selectedTransposition
        )
        .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5)
        .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
        .task {
            playlistManager.loadSongsFromBundle() // Load songs when the view appears
            do {
                try await pitchDetector.activate()
            } catch {
                // TODO: Handle error
                print(error)
            }
        }
        .alert(isPresented: $pitchDetector.showMicrophoneAccessAlert) {
            MicrophoneAccessAlert()
        }
    }
}

struct TunerScreen_Previews: PreviewProvider {
    static var previews: some View {
        TunerScreen()
    }
}
