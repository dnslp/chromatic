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
                    .animation(.easeInOut, value: tunerData.closestNote.distance) // Animation per tick
                    .inExpandingRectangle()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // It's generally better to apply a single animation modifier to the container
        // if all elements within animate based on the same value change.
        // However, if individual ticks need to animate independently based on their own color changes,
        // then animating each Rectangle might be intended.
        // For now, moving animation to each rectangle as it's more likely to reflect individual changes.
        // If the whole block of ticks should animate together, it should be on the HStack.
        // Let's stick to animating individual rectangles for now as per previous step.
        .alignmentGuide(.noteTickCenter) { dimensions in
            dimensions[VerticalAlignment.center]
        }
    }

    private func colorForTick(atIndex index: Int) -> Color {
        let currentPitchActualDistance = tunerData.closestNote.distance // e.g., +10 cents (sharp)
        let tickPositionInCents = Double(index - 12) // e.g., tick at index 13 is +1 cent from center

        let greenZoneHalfWidth: Double = 2.5
        let yellowZoneHalfWidth: Double = 7.5

        let diffFromActualPitch = tickPositionInCents - currentPitchActualDistance

        if currentPitchActualDistance > greenZoneHalfWidth && tickPositionInCents < 0 {
            return .secondary
        }
        if currentPitchActualDistance < -greenZoneHalfWidth && tickPositionInCents > 0 {
            return .secondary
        }

        let isTickOnCorrectSideOrPitchInTune: Bool =
            (currentPitchActualDistance >= 0 && tickPositionInCents >= -greenZoneHalfWidth) ||
            (currentPitchActualDistance <= 0 && tickPositionInCents <= greenZoneHalfWidth) ||
            abs(currentPitchActualDistance) <= greenZoneHalfWidth

        if isTickOnCorrectSideOrPitchInTune {
            if abs(diffFromActualPitch) <= greenZoneHalfWidth {
                return .imperceptibleMusicalDistance
            } else if abs(diffFromActualPitch) <= yellowZoneHalfWidth {
                return .slightlyPerceptibleMusicalDistance
            } else {
                if !((currentPitchActualDistance > yellowZoneHalfWidth && tickPositionInCents < currentPitchActualDistance) ||
                     (currentPitchActualDistance < -yellowZoneHalfWidth && tickPositionInCents > currentPitchActualDistance)) {
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
        Group {
            NoteDistanceMarkers(tunerData: TunerData(pitch: 440.0, amplitude: 0.5)) // In tune
                .previewDisplayName("In Tune")
            NoteDistanceMarkers(tunerData: TunerData(pitch: 443.0, amplitude: 0.5)) // Slightly Sharp (+11.8 cents)
                .previewDisplayName("Slightly Sharp")
            NoteDistanceMarkers(tunerData: TunerData(pitch: 452.0, amplitude: 0.5)) // Very Sharp (+47 cents)
                .previewDisplayName("Very Sharp")
            NoteDistanceMarkers(tunerData: TunerData(pitch: 437.0, amplitude: 0.5)) // Slightly Flat (-11.9 cents)
                .previewDisplayName("Slightly Flat")
            NoteDistanceMarkers(tunerData: TunerData(pitch: 429.0, amplitude: 0.5)) // Very Flat (-43 cents)
                .previewDisplayName("Very Flat")
        }
        .previewLayout(.fixed(width: 300, height: 200))
        .background(Color.gray.opacity(0.2))
    }
}
