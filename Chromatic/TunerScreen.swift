import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int

    var body: some View {
        TunerView(
            tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude), // Pass amplitude
            modifierPreference: modifierPreference,
            selectedTransposition: selectedTransposition
        )
        .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5)
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
        TunerScreen(
            pitchDetector: MicrophonePitchDetector(engine: AudioEngine()),
            modifierPreference: .constant(.preferSharps),
            selectedTransposition: .constant(0)
        )
    }
}
