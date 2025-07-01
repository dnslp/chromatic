import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject private var pitchDetector = MicrophonePitchDetector()
    @AppStorage("modifierPreference")
    private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition")
    private var selectedTransposition = 0

    var body: some View {
        TunerView(
            tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude), // Pass amplitude
            micIsActive: pitchDetector.didReceiveAudio, // Pass the mic status
            modifierPreference: modifierPreference,
            selectedTransposition: selectedTransposition
        )
        .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5) // Keep existing opacity behavior
        .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
        .task {
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
