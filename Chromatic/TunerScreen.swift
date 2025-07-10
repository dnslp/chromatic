import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    @State private var tunerData: TunerData
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var countdown: Int? = nil
    let countdownSeconds = 3 // Change if you want a different start delay

    var userF0: Double {
        profileManager.currentProfile?.f0 ?? 77.78 // fallback value
    }
    
    init(pitchDetector: MicrophonePitchDetector, modifierPreference: Binding<ModifierPreference>, selectedTransposition: Binding<Int>) {
        self.pitchDetector = pitchDetector
        self._tunerData = State(initialValue: TunerData())
        self._modifierPreference = modifierPreference
        self._selectedTransposition = selectedTransposition
    }
    
    var body: some View {
        
//        TunerPlanet(
//            tunerData: $tunerData, // <-- pass as a binding!
//            modifierPreference: modifierPreference,
//            selectedTransposition: selectedTransposition
//        )
//        PlanetaryPitchView(
//            f0: userF0,
//            liveHz: tunerData.pitch.measurement.value
//        )
//        .frame(width: 320, height: 320)
//        .padding(.top, 16)
        
//        PitchOrbitView(
//            liveHz: tunerData.pitch.measurement.value,
//            f0: userF0,
//            fourth: userF0 * 4 / 3,
//            fifth: userF0 * 3 / 2,
//            harmonics: (2...5).map { userF0 * Double($0) }
//        )
//        .padding()
//        TunerViewTemplate(
//            tunerData: $tunerData,
//            modifierPreference: modifierPreference,
//            selectedTransposition: selectedTransposition
//        )
        TunerStreak(tunerData: $tunerData, modifierPreference: modifierPreference, selectedTransposition: selectedTransposition)
//        StringTheoryView(
//            tunerData: $tunerData,
//            modifierPreference: modifierPreference,
//            selectedTransposition: selectedTransposition
//        )
        .environmentObject(profileManager)
//        TunerViewZen(tunerData: $tunerData)
//        TunerView(
//            tunerData: $tunerData, // Pass as a binding
//            modifierPreference: modifierPreference,
//            selectedTransposition: selectedTransposition
//        )
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
        .environmentObject(UserProfileManager())
    }
}
