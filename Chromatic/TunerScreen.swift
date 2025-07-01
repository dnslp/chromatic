import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector // Accept as a parameter
    @AppStorage("modifierPreference")
    private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition")
    private var selectedTransposition = 0

    var body: some View {
        TunerView(
            tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude),
            modifierPreference: modifierPreference,
            selectedTransposition: selectedTransposition
        )
        .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5)
        .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
        .task { // This task will run when TunerScreen appears
            do {
                // Only activate if not already activated by another view or previous appearance
                if !pitchDetector.isRecording {
                    try await pitchDetector.activate()
                }
            } catch {
                // TODO: Handle error
                print("Error activating pitch detector in TunerScreen: \(error)")
            }
        }
        .alert(isPresented: $pitchDetector.showMicrophoneAccessAlert) {
            MicrophoneAccessAlert()
        }
    }
}

struct TunerScreen_Previews: PreviewProvider {
    static var previews: some View {
        // For previews, we need to provide a mock or a fresh instance.
        // Using a fresh instance for simplicity here.
        TunerScreen(pitchDetector: MicrophonePitchDetector())
    }
}
