import MicrophonePitchDetector
import SwiftUI

enum TunerDisplay: String, CaseIterable, Identifiable {
    case planet        = "Planet"
//    case orbital       = "Orbit"
    case streak        = "Streak"
    case template      = "Template"
    case stringTheory  = "String Theory"
    case zen           = "Zen"
    case defaultView   = "Default"


    var id: String { rawValue }
}

struct TunerScreen: View {
    @State private var streak: Int = 0
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    @State private var tunerData: TunerData
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int
    @EnvironmentObject var profileManager: UserProfileManager

    @State private var selectedDisplay: TunerDisplay = .streak
    @State private var countdown: Int? = nil
    let countdownSeconds = 3

    var userF0: Double {
        profileManager.currentProfile?.f0 ?? 77.78
    }

    init(
        pitchDetector: MicrophonePitchDetector,
        modifierPreference: Binding<ModifierPreference>,
        selectedTransposition: Binding<Int>
    ) {
        self.pitchDetector = pitchDetector
        self._tunerData = State(initialValue: TunerData())
        self._modifierPreference = modifierPreference
        self._selectedTransposition = selectedTransposition
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("View", selection: $selectedDisplay) {
                ForEach(TunerDisplay.allCases) { view in
                    Text(view.rawValue).tag(view)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            viewForSelectedDisplay()
                .environmentObject(profileManager)
        }
        .padding(.top, 80)
        // Update TunerData whenever the pitch changes:
        .onChange(of: pitchDetector.pitch) { newPitch in
            var newData = TunerData(pitch: newPitch, amplitude: pitchDetector.amplitude)
            newData.isRecording = tunerData.isRecording
            newData.recordedPitches = tunerData.recordedPitches
            if newData.isRecording {
                newData.addPitch(newPitch)
            }
            self.tunerData = newData
        }
        // Dim when no audio is present
        .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5)
        .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
        // Activate the microphone on appear
        .task {
            do {
                try await pitchDetector.activate()
            } catch {
                print("Mic activation error:", error)
            }
        }
        .alert(isPresented: $pitchDetector.showMicrophoneAccessAlert) {
            MicrophoneAccessAlert()
        }
    }

    @ViewBuilder
    private func viewForSelectedDisplay() -> some View {
        switch selectedDisplay {
        case .planet:
            TunerPlanet(
                tunerData: $tunerData,
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
//        case .orbital:
//            PitchOrbitView(
//                liveHz: tunerData.pitch.measurement.value,
//                f0: userF0,
//                fourth: userF0 * 4 / 3,
//                fifth: userF0 * 3 / 2,
//                harmonics: (2...5).map { userF0 * Double($0) }
//            )
//            .frame(width: 320, height: 320)
//            .padding(.top, 16)
        case .streak:
            TunerStreak(
                tunerData: $tunerData,
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
        case .template:
            TunerViewTemplate(
                tunerData: $tunerData,
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
        case .stringTheory:
            StringTheoryView(
                tunerData: $tunerData,
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
        case .zen:
            TunerViewZen(tunerData: $tunerData)
        case .defaultView:
            TunerView(
                tunerData: $tunerData,
                modifierPreference: modifierPreference,
                selectedTransposition: selectedTransposition
            )
        }
    }
}

struct TunerScreen_Previews: PreviewProvider {
    static var previews: some View {
        let detector = MicrophonePitchDetector()
        TunerScreen(
            pitchDetector: detector,
            modifierPreference: .constant(.preferSharps),
            selectedTransposition: .constant(0)
        )
        .environmentObject(UserProfileManager())
    }
}
