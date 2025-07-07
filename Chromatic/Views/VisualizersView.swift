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
        @State var mockTunerData = TunerData(
            pitch: 440.0,
            amplitude: 0.8,
            closestNote: ScaleNote.Match(scaleNote: .A, distance: .init(cents: 0, frequency: 440), octave: 4, rawFrequency: 440),
            recordedPitches: [
                RecordedPitch(frequency: 440,-0.5),
                RecordedPitch(frequency: 441,0.5),
                RecordedPitch(frequency: 439,-0.2)
            ]
        )
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
