import SwiftUI

struct RecordingControlView: View {
    @StateObject var viewModel: RecordingViewModel // ViewModel will be initialized by the parent
    @Binding var tunerData: TunerData // For passing to StatsModalView

    var body: some View {
        Group { // Use Group to handle conditional content at the root level
            if let countdown = viewModel.countdown {
                VStack {
                    CalmingCountdownCircle(secondsLeft: countdown, totalSeconds: viewModel.countdownSeconds)
                        .frame(width: 140, height: 140)
                        .padding(.bottom, 8)
                    Text("Recording begins in \(countdown)…")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.startOrStopRecording()
                    }) {
                        Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(viewModel.isRecording ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        viewModel.clearRecordingData()
                    }) {
                        Text("Clear Data")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .sheet(isPresented: $viewModel.showStatsModal) {
                    // Ensure viewModel.sessionStats and tunerData.recordedPitches are available and correctly typed
                    if let stats = viewModel.sessionStats {
                        StatsModalView(
                            statistics: stats.pitch, // Assuming stats.pitch matches expected type
                            duration: stats.duration, // Assuming stats.duration matches
                            values: tunerData.recordedPitches // Ensure this matches what StatsModalView expects
                        )
                    } else {
                        // Fallback or placeholder if stats are not available
                        Text("Statistics not available.")
                    }
                }
            }
        }
        // This listener ensures that if tunerData.isRecording changes from an external source
        // (e.g. another part of the app stops the recording), the ViewModel is updated.
        .onChange(of: tunerData.isRecording) { newIsRecording in
            viewModel.syncRecordingState(isRecording: newIsRecording)
        }
    }
}

struct RecordingControlView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock TunerData for the preview
        @State var mockTunerData = TunerData(pitch: 440, amplitude: 0.5)

        // Initialize RecordingViewModel with the mock TunerData
        // Note: For previews, StateObject can be initialized directly.
        // In a real app, you'd typically pass it from a parent view or initialize it
        // in a way that its lifecycle is correctly managed.
        RecordingControlView(
            viewModel: RecordingViewModel(tunerData: mockTunerData),
            tunerData: $mockTunerData
        )
        .padding()
        .previewLayout(.sizeThatFits)

        // Preview for countdown state
        let countdownViewModel = RecordingViewModel(tunerData: mockTunerData)
        let _ = countdownViewModel.countdown = 3 // Manually set state for preview
        RecordingControlView(
            viewModel: countdownViewModel,
            tunerData: $mockTunerData
        )
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Countdown State")
    }
}
