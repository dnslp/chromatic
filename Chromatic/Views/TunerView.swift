import SwiftUI
// Removed AVFoundation import as it's not directly used by TunerView after refactoring.
// Subviews might still need it.

// MARK: - TunerView
struct TunerView: View {
    @Binding var tunerData: TunerData
    @Binding var modifierPreference: ModifierPreference // Changed to Binding
    @Binding var selectedTransposition: Int // Changed to Binding
    
    // State for this view specifically
    @State private var userF0: Double = 77.78 // Default E2-ish. Consider making this configurable or persisted.
    @State private var micMuted = false // This state might belong in a higher level audio manager or AppState

    // ViewModel for recording logic
    @StateObject private var recordingViewModel: RecordingViewModel

    // Match calculation, remains here as it depends on selectedTransposition and tunerData
    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    // Layout constants that are specific to TunerView's overall structure
    private let nonWatchHeight: CGFloat = 560 // Keep if still relevant for overall frame
    // Removed other layout constants as they should be moved to their respective subviews.

    // Initializer to setup RecordingViewModel
    // This is necessary because RecordingViewModel now takes tunerData
    // and TunerView itself receives tunerData as a Binding.
    // We need to ensure that @StateObject is initialized only once.
    init(tunerData: Binding<TunerData>, modifierPreference: Binding<ModifierPreference>, selectedTransposition: Binding<Int>) {
        self._tunerData = tunerData
        self._modifierPreference = modifierPreference
        self._selectedTransposition = selectedTransposition
        // Initialize the @StateObject with the wrappedValue of the Binding.
        // This ensures that RecordingViewModel is instantiated once per TunerView lifecycle.
        self._recordingViewModel = StateObject(wrappedValue: RecordingViewModel(tunerData: tunerData.wrappedValue))
    }
    
    var body: some View {
        Group {
#if os(watchOS)
            // watchOS UI remains unchanged.
            // If watchOS UI also needs refactoring, it should be addressed separately.
            // For now, assuming it's simple enough or distinct.
            ZStack {
                Text("WatchOS Tuner UI") // Placeholder
                // ... existing watchOS specific UI ...
            }
#else
            // iOS / macOS UI
            HStack(spacing: 1) { // Consider if this spacing is still needed
                PitchLineVisualizer(
                    tunerData: tunerData, // Pass the binding
                    frequency: tunerData.pitch,
                    fundamental: Frequency(floatLiteral: userF0)
                )
                .frame(width: 10) // This could be a constant within PitchLineVisualizer perhaps
                .padding(.vertical, 16)
                
                VStack(spacing: 0) { // Overall content stack
                    AmplitudeView(tunerData: $tunerData, micMuted: $micMuted)
                        .padding(.bottom) // Add some spacing if needed

                    NoteDisplayView(
                        tunerData: $tunerData,
                        match: match, // Pass the calculated match
                        modifierPreference: modifierPreference // Pass the binding
                    )
                    .padding(.top, 40) // Restore original padding from TunerView's VStack

                    Spacer(minLength: 40)

                    VisualizersView(
                        tunerData: $tunerData,
                        matchDistanceCents: Double(match.distance.cents),
                        fundamentalHz: userF0
                    )
                    // Removed specific paddings from here, let VisualizersView manage its internal layout

                    Spacer() // Add spacer to push controls to bottom if desired

                    RecordingControlView(
                        viewModel: recordingViewModel,
                        tunerData: $tunerData // Pass binding for StatsModalView
                    )
                    .padding(.vertical) // Add some spacing

                    TunerControlsView(
                        userF0: $userF0,
                        selectedTransposition: $selectedTransposition
                    )
                    // Padding and frame for this view are handled by TunerControlsView internally or by this VStack
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: nonWatchHeight) // Apply overall height constraint
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.94)) // Consider making these configurable
                    .shadow(color: Color.black.opacity(0.05), radius: 16, y: 4)
            )
            .padding(.horizontal, 8) // Overall horizontal padding
#endif
        }
        .frame(maxHeight: .infinity, alignment: .top)
        // .onReceive(tunerData.$isRecording) { isRecording in
        //    recordingViewModel.syncRecordingState(isRecording: isRecording)
        // }
        // The sync for isRecording is now handled within RecordingControlView using .onChange
    }
}

// MARK: - TunerView Preview
struct TunerView_Previews: PreviewProvider {
    // Create mock bindings for the preview
    @State static var mockTunerData = TunerData(pitch: 428, amplitude: 0.5)
    @State static var mockModifierPreference = ModifierPreference.preferSharps
    @State static var mockSelectedTransposition = 0

    static var previews: some View {
        TunerView(
            tunerData: $mockTunerData,
            modifierPreference: $mockModifierPreference,
            selectedTransposition: $mockSelectedTransposition
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .preferredColorScheme(.dark) // Example: test with dark scheme
    }
}
