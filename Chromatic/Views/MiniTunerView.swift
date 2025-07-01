import SwiftUI
import MicrophonePitchDetector

struct MiniTunerView: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    @AppStorage("modifierPreference") private var modifierPreference = ModifierPreference.preferSharps
    @AppStorage("selectedTransposition") private var selectedTransposition = 0
    // Optional: Add a variable to control visibility if no audio is detected yet
    // @State private var hasDetectedAudioInitially: Bool = false

    private var tunerData: TunerData {
        TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude)
    }

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    var body: some View {
        // Only display if audio has been received, or perhaps after a brief moment
        // to avoid layout shifts if pitchDetector takes a moment to initialize.
        // Using pitchDetector.didReceiveAudio directly.
        if pitchDetector.didReceiveAudio {
            VStack(alignment: .center) {
                MatchedNoteView(
                    match: match,
                    modifierPreference: modifierPreference
                )
                .scaleEffect(0.8) // Make it a bit smaller

                MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                    .scaleEffect(0.8) // Make it a bit smaller
            }
            .padding(.vertical, 5) // Add some minimal padding
            .background(Color.gray.opacity(0.1)) // Subtle background to differentiate
            .cornerRadius(8)
            .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
            // Ensure the microphone is active if this view appears and it's not already.
            // This is important if a tab with MiniTunerView is the first one opened.
            .task {
                do {
                    if !pitchDetector.isRecording {
                        try await pitchDetector.activate()
                    }
                    // if !hasDetectedAudioInitially && pitchDetector.didReceiveAudio {
                    //     hasDetectedAudioInitially = true
                    // }
                } catch {
                    print("Error activating pitch detector in MiniTunerView: \(error)")
                    // Optionally, handle the error (e.g., show a message to the user)
                }
            }
            .alert(isPresented: $pitchDetector.showMicrophoneAccessAlert) {
                // Re-use the existing alert defined in your project
                // This assumes MicrophoneAccessAlert is a simple struct returning an Alert
                MicrophoneAccessAlert()
            }
        } else {
            // Placeholder or empty view if no audio detected yet, to prevent UI jumping
            // Or you could show a "Listening..." text
            Text("Listening...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 5)
                .frame(minHeight: 60) // Estimate based on scaled content
                .task { // Also attempt to activate here
                     do {
                        if !pitchDetector.isRecording {
                            try await pitchDetector.activate()
                        }
                    } catch {
                        print("Error activating pitch detector in MiniTunerView (initial): \(error)")
                    }
                }
        }
    }
}

struct MiniTunerView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock pitch detector for preview
        let mockDetector = MicrophonePitchDetector()
        // Simulate receiving audio for preview if needed
        // mockDetector.didReceiveAudio = true
        // mockDetector.pitch = 440.0 // A4

        return MiniTunerView(pitchDetector: mockDetector)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
