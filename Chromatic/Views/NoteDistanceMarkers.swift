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
        let currentPitchActualDistanceCents = abs(Double(tunerData.closestNote.distance.cents))
        let tickPositionRelativeToCenter = index - 12 // 0 for center, negative for flat, positive for sharp

        var baseSize: NoteTickSize
        switch abs(tickPositionRelativeToCenter) {
        case 0: // Center tick (index 12)
            baseSize = .large
        case 6: // Approx +/- 24 cents if 1 tick = 4 cents (e.g. indices 6 and 18)
            baseSize = .medium
        case 12: // End ticks (indices 0 and 24)
            baseSize = .medium
        default:
            baseSize = .small
        }

        var height = baseSize.height

        // Dynamic adjustments
        let inTuneThreshold: Double = 5.0
        let slightlyOffThreshold: Double = 15.0

        if tickPositionRelativeToCenter == 0 { // Center tick adjustments
            if currentPitchActualDistanceCents <= inTuneThreshold {
                height *= 1.2 // Boost height when in tune
            } else if currentPitchActualDistanceCents > slightlyOffThreshold {
                height *= 0.8 // Reduce height when very out of tune
            }
        } else {
            // For non-center ticks, consider if they are near the current pitch when it's off
            if currentPitchActualDistanceCents > slightlyOffThreshold {
                // If this tick is close to where the current out-of-tune pitch is
                // Example: pitch is +20 cents, tick is at +5 (index 17, assuming 1 tick = 4 cents, so +20 cents)
                // tickPositionInCents = Double(tickPositionRelativeToCenter) * 4.0 (approx)
                // For simplicity, let's say if a tick is within +/- 2 ticks of the current "zone" of deviation
                let pitchZone = Int(round(Double(tunerData.closestNote.distance.cents) / 4.0)) // Approx which tick zone current pitch is in
                if abs(tickPositionRelativeToCenter - pitchZone) <= 2 {
                     height *= 1.15 // Slightly boost ticks near the current (very off) pitch
                }
            } else if currentPitchActualDistanceCents <= inTuneThreshold {
                 height *= 0.9 // Slightly reduce other ticks when in tune to emphasize center
            }
        }

        // Clamping the height to avoid extreme sizes, min height of small, max of large * 1.2
        let minHeight = NoteTickSize.small.height
        let maxHeight = NoteTickSize.large.height * 1.25
        return .custom(max(minHeight, min(height, maxHeight)))
    }
}

enum NoteTickSize {
    case small, medium, large
    case custom(CGFloat)

    var height: CGFloat {
        switch self {
        case .small:  return 60
        case .medium: return 100
        case .large:  return 180
        case .custom(let h): return h
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
