import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    @State private var tunerData: TunerData
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int

    init(pitchDetector: MicrophonePitchDetector, modifierPreference: Binding<ModifierPreference>, selectedTransposition: Binding<Int>) {
        self.pitchDetector = pitchDetector
        self._tunerData = State(initialValue: TunerData())
        self._modifierPreference = modifierPreference
        self._selectedTransposition = selectedTransposition
    }

    var body: some View {
        TunerView(
            tunerData: $tunerData, // Pass as a binding
            modifierPreference: modifierPreference,
            selectedTransposition: selectedTransposition
        )
        .onChange(of: pitchDetector.pitch) { newPitch in
            // Create a new TunerData instance for the update
            // This is important because TunerData is a struct.
            // We need to ensure that the reference itself changes for SwiftUI to detect the change for some views.
            var newTunerDataInstance = TunerData(pitch: newPitch, amplitude: pitchDetector.amplitude)

            // Preserve recording state and data from the current tunerData
            newTunerDataInstance.isRecording = tunerData.isRecording
            newTunerDataInstance.recordedPitches = tunerData.recordedPitches

            // If recording, add the new pitch
            if newTunerDataInstance.isRecording {
                newTunerDataInstance.addPitch(newPitch) // This will add to its own recordedPitches
            }

            // Assign the new instance to self.tunerData to trigger view updates
            self.tunerData = newTunerDataInstance
        }
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
        let pitchDetector = MicrophonePitchDetector()
        // Manually set a pitch for preview if needed, e.g., pitchDetector.pitch = 440.0
        return TunerScreen(
            pitchDetector: pitchDetector,
            modifierPreference: .constant(.preferSharps),
            selectedTransposition: .constant(0)
        )
    }
}
