import SwiftUI

struct NoteDistanceMarkers: View {
    let tunerData: TunerData

    var body: some View {
        HStack {
            ForEach(0..<25) { index in
                Rectangle()
                    .frame(width: 1, height: tickSize(forIndex: index).height)
                    .cornerRadius(1)
                    .foregroundColor(colorForTick(atIndex: index))
                    .animation(.easeInOut, value: tunerData.closestNote.distance.cents) // Animate based on cents
                    .inExpandingRectangle()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .alignmentGuide(.noteTickCenter) { dimensions in
            dimensions[VerticalAlignment.center]
        }
    }

    private func colorForTick(atIndex index: Int) -> Color {
        let currentPitchActualDistanceCents = Double(tunerData.closestNote.distance.cents) // Use .cents and cast to Double
        let tickPositionInCents = Double(index - 12) // This is already a Double representing cents offset

        // Thresholds (as Doubles for comparison with Double types)
        let greenZoneHalfWidth: Double = 2.5
        let yellowZoneHalfWidth: Double = 7.5

        let diffFromActualPitch = tickPositionInCents - currentPitchActualDistanceCents

        if currentPitchActualDistanceCents > greenZoneHalfWidth && tickPositionInCents < 0 {
            return .secondary
        }
        if currentPitchActualDistanceCents < -greenZoneHalfWidth && tickPositionInCents > 0 {
            return .secondary
        }

        let isTickOnCorrectSideOrPitchInTune: Bool =
            (currentPitchActualDistanceCents >= 0 && tickPositionInCents >= -greenZoneHalfWidth) ||
            (currentPitchActualDistanceCents <= 0 && tickPositionInCents <= greenZoneHalfWidth) ||
            abs(currentPitchActualDistanceCents) <= greenZoneHalfWidth

        if isTickOnCorrectSideOrPitchInTune {
            if abs(diffFromActualPitch) <= greenZoneHalfWidth {
                return .imperceptibleMusicalDistance
            } else if abs(diffFromActualPitch) <= yellowZoneHalfWidth {
                return .slightlyPerceptibleMusicalDistance
            } else {
                // Only color red if it's not "behind" the current pitch direction when pitch is far off
                if !((currentPitchActualDistanceCents > yellowZoneHalfWidth && tickPositionInCents < currentPitchActualDistanceCents) ||
                     (currentPitchActualDistanceCents < -yellowZoneHalfWidth && tickPositionInCents > currentPitchActualDistanceCents)) {
                    return .perceptibleMusicalDistance
                }
            }
        }
        return .secondary
    }

    private func tickSize(forIndex index: Int) -> NoteTickSize {
        switch index {
        case 12:           .large
        case 6, 18:        .medium
        case 0, 24:        .medium
        default:           .small
        }
    }
}

enum NoteTickSize {
    case small, medium, large

    var height: CGFloat {
        switch self {
        case .small:  60
        case .medium: 100
        case .large:  180
        }
    }
}

extension View {
    func inExpandingRectangle() -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
            self
        }
    }
}

struct NoteDistanceMarkers_Previews: PreviewProvider {
    static var previews: some View {
        // Helper to create TunerData; assumes A4 = 440 Hz for pitch calculations if not perfectly on a note
        // The TunerData init will calculate the 'closestNote' and its 'distance'
        let makeTunerData = { (hz: Double) -> TunerData in
            TunerData(pitch: hz, amplitude: 0.5)
        }

        Group {
            NoteDistanceMarkers(tunerData: makeTunerData(440.0)) // In tune (A4)
                .previewDisplayName("In Tune (A4)")
            NoteDistanceMarkers(tunerData: makeTunerData(443.0)) // Slightly Sharp from A4 (+11.8 cents)
                .previewDisplayName("Slightly Sharp")
            NoteDistanceMarkers(tunerData: makeTunerData(452.0)) // Very Sharp from A4 (+47 cents)
                .previewDisplayName("Very Sharp")
            NoteDistanceMarkers(tunerData: makeTunerData(437.0)) // Slightly Flat from A4 (-11.9 cents)
                .previewDisplayName("Slightly Flat")
            NoteDistanceMarkers(tunerData: makeTunerData(429.0)) // Very Flat from A4 (-43 cents)
                .previewDisplayName("Very Flat")
            NoteDistanceMarkers(tunerData: makeTunerData(261.63)) // In tune (C4)
                .previewDisplayName("In Tune (C4)")
            NoteDistanceMarkers(tunerData: makeTunerData(263.0)) // Slightly sharp from C4
                .previewDisplayName("Slightly Sharp (C4)")
        }
        .previewLayout(.fixed(width: 300, height: 200))
        .background(Color.gray.opacity(0.2))
    }
}
