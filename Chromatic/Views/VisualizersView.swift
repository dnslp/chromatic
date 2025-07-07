import SwiftUI

struct VisualizersView: View {
    @Binding var tunerData: TunerData
    let matchDistanceCents: Double
    let fundamentalHz: Double // userF0

    private let maxCentDistance: Double = 50 // From original TunerView

    var body: some View {
        VStack { // Added a VStack to group them, adjust as needed
            ConcentricCircleVisualizer(
                distance: matchDistanceCents,
                maxDistance: maxCentDistance,
                tunerData: tunerData, // Make sure ConcentricCircleVisualizer is adapted if it needs specific parts of TunerData
                fundamentalHz: fundamentalHz
            )
            .frame(width: 100, height: 100)
            .padding(.bottom, 20)

            HarmonicGraphView(tunerData: tunerData)
                .frame(height: 30)

            PitchChakraTimelineView(pitches: tunerData.recordedPitches)
                .frame(height: 48)
        }
    }
}

struct VisualizersView_Previews: PreviewProvider {
    static var previews: some View {
        // Correctly initialize mockTunerData for the preview
        let initialMockTunerData = TunerData(
            pitch: 440.0,
            amplitude: 0.8
            // closestNote will be calculated by TunerData's init
            // recordedPitches will be set manually below for the preview
        )

        // Use a state variable for the preview if modifications are needed,
        // or construct it fully before passing if it's static for the preview's purpose.
        // For this preview, we'll create a more complete mockTunerData instance.
        @State var mockTunerData: TunerData = {
            var data = TunerData(
                pitch: 440.0,
                amplitude: 0.8
            )
            // Manually set recordedPitches for the preview as TunerData's init doesn't take it.
            data.recordedPitches = [440.0, 441.5, 439.0, 442.0, 438.5, 440.0, 441.0]
            // If needed, adjust other properties like closestNote to match a specific scenario.
            // For simplicity, we rely on the default calculation in TunerData's init for closestNote.
            // If a specific closestNote is needed for the preview, it would require a custom init or modification here.
            return data
        }()

        // Example values for preview
        let mockMatchDistanceCents: Double = 10.0
        let mockFundamentalHz: Double = 440.0

        VisualizersView(
            tunerData: $mockTunerData,
            matchDistanceCents: mockMatchDistanceCents,
            fundamentalHz: mockFundamentalHz
        )
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color(.systemGray5))
    }
}
