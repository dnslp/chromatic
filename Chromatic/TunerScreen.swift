import MicrophonePitchDetector
import SwiftUI

struct TunerScreen: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int
    @Environment(\.scenePhase) var scenePhase


    var body: some View {
        TunerView(
            pitchDetector: pitchDetector, // Pass the pitchDetector instance
            tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude),
            modifierPreference: modifierPreference,
            selectedTransposition: selectedTransposition
        )
        .opacity(pitchDetector.didReceiveAudio || pitchDetector.microphoneState == .muted ? 1 : 0.5) // Remain fully opaque if muted
        .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
        .task {
            do {
                // Activate will now handle initial state internally
                try await pitchDetector.activate()
            } catch {
                // TODO: Handle error (e.g., show an alert to the user)
                print("Error activating pitch detector: \(error)")
            }
        }
        .alert(isPresented: $pitchDetector.showMicrophoneAccessAlert) {
            MicrophoneAccessAlert()
        }
        .onChange(of: scenePhase) { newPhase in
            Task {
                if newPhase == .active {
                    do {
                        try await pitchDetector.resume()
                    } catch {
                        print("Error resuming pitch detector: \(error)")
                    }
                } else if newPhase == .inactive || newPhase == .background {
                    // No need to await suspend if it's synchronous
                    pitchDetector.suspend()
                }
            }
        }
    }
}
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
            pitchDetector: MicrophonePitchDetector(),
            modifierPreference: .constant(.preferSharps),
            selectedTransposition: .constant(0)
        )
    }
}
