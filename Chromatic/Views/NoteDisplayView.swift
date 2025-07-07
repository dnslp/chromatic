import SwiftUI

struct NoteDisplayView: View {
    @Binding var tunerData: TunerData // For NoteTicks and closestNote
    let match: ScaleNote.Match // Passed directly
    let modifierPreference: ModifierPreference // Passed directly

    private let contentSpacing: CGFloat = 8
    private let noteTicksHeight: CGFloat = 100

    var body: some View {
        VStack(spacing: contentSpacing) {
            MatchedNoteView(match: match, modifierPreference: modifierPreference)
                .padding(.top, 50) // This padding seems specific, ensure it's desired
            MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                .padding(.bottom, 50) // This padding also seems specific
            NoteTicks(tunerData: tunerData, showFrequencyText: true)
                .frame(height: noteTicksHeight)
                .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        // .padding(.top, 40) // This was in the original VStack, evaluate if it belongs here or in the parent
    }
}

struct NoteDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock data for preview
        @State var mockTunerData = TunerData(pitch: 440.0, amplitude: 0.8)
        // Setup a mock match. You might need to define a simplified ScaleNote.Match or use actual.
        // For simplicity, let's assume ScaleNote.Match can be mocked or an instance created.
        // This requires ScaleNote and its related types to be accessible.
        let mockMatch = ScaleNote.Match(
            scaleNote: .C, // Example value
            distance: .init(cents: 0, frequency: 440.0), // Example value
            octave: 4, // Example value
            rawFrequency: 440.0 // Example value
        )

        NoteDisplayView(
            tunerData: $mockTunerData,
            match: mockMatch,
            modifierPreference: .preferSharps
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemGray6)) // Add background for better visibility in preview
    }
}
