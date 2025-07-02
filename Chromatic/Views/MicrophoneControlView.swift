//
//  MicrophoneControlView.swift
//  Chromatic
//
//  Created by Jules on 10/24/2023.
//

import SwiftUI
// Assuming MicrophonePitchDetector and MicrophoneState are accessible.
// If MicrophonePitchDetector is in a separate package, ensure it's imported.
// import MicrophonePitchDetectorModule // Example if it were a module

struct MicrophoneControlView: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector

    // For the Push-to-Talk button state
    @State private var isPushToTalkPressed: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Picker("Mic Mode", selection: $pitchDetector.microphoneState) {
                ForEach(MicrophoneState.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: pitchDetector.microphoneState) { newState in
                Task {
                    do {
                        try await pitchDetector.setMicrophoneState(newState)
                    } catch {
                        // Handle error (e.g., show an alert to the user)
                        print("Error setting microphone state: \(error)")
                        // Optionally revert to old state or handle UI feedback
                    }
                }
            }

            if pitchDetector.microphoneState == .pushToTalk {
                Button(action: {
                    // This action is primarily for accessibility / tap interaction.
                    // The main interaction is press-and-hold.
                    // We could toggle a brief listen period here if desired,
                    // but current plan relies on long press.
                }) {
                    Text("Hold to Talk")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isPushToTalkPressed ? Color.green.opacity(0.5) : Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 2, y: 1)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.01) // Trigger almost immediately
                        .onChanged { pressing in
                            // This callback might be called multiple times; use a state variable
                            // if you need to track the start/end precisely.
                            // For now, direct call to toggle PTT.
                        }
                        .onEnded { _ in
                            // This is called when the long press ends
                            if isPushToTalkPressed { // Ensure it was actually pressed
                                Task {
                                    do {
                                        try await pitchDetector.togglePushToTalk(isPressed: false)
                                        self.isPushToTalkPressed = false
                                    } catch {
                                        print("Error on PTT release: \(error)")
                                    }
                                }
                            }
                        }
                )
                // It's more reliable to use a DragGesture to detect the start of the press
                // for immediate feedback, combined with the LongPress for the "hold" intention.
                // However, a simpler approach for "press and hold" effect is often a custom button style
                // or using .onTapGesture with a custom press state management if LongPressGesture is tricky.
                // Let's refine the PTT button interaction.
                // A common pattern is to use @State for pressed and update via .gesture
                // For a button that needs to react to down and up state of a press:
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPushToTalkPressed { // Activate on first touch
                                self.isPushToTalkPressed = true
                                Task {
                                    do {
                                        try await pitchDetector.togglePushToTalk(isPressed: true)
                                    } catch {
                                        print("Error on PTT press: \(error)")
                                        self.isPushToTalkPressed = false // Reset if error
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            if isPushToTalkPressed { // Deactivate on release
                                self.isPushToTalkPressed = false
                                Task {
                                    do {
                                        try await pitchDetector.togglePushToTalk(isPressed: false)
                                    } catch {
                                        print("Error on PTT release: \(error)")
                                    }
                                }
                            }
                        }
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 8) // Add a little space from the top content
    }
}

// Preview needs a mock pitch detector
class MockPitchDetector: MicrophonePitchDetector {
    // You can override properties or methods if needed for different preview states
}

struct MicrophoneControlView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with .on state
        let detectorOn = MockPitchDetector()
        detectorOn.microphoneState = .on

        // Preview with .muted state
        let detectorMuted = MockPitchDetector()
        detectorMuted.microphoneState = .muted

        // Preview with .pushToTalk state
        let detectorPTT = MockPitchDetector()
        detectorPTT.microphoneState = .pushToTalk

        return Group {
            MicrophoneControlView(pitchDetector: detectorOn)
                .previewDisplayName("State: On")

            MicrophoneControlView(pitchDetector: detectorMuted)
                .previewDisplayName("State: Muted")

            MicrophoneControlView(pitchDetector: detectorPTT)
                .previewDisplayName("State: PushToTalk")
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color(.systemBackground))
    }
}
