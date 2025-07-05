import SwiftUI

/// A vertical stack of distance ticks where each tick is a horizontal bar.
/// Colors and sizes adjust based on the current pitch error.
struct NoteDistanceMarkers: View {
    let tunerData: TunerData

    // Configuration
    private let tickCount = 13
    private let centerIndex = 12
    private let maxDistanceCents: Double = 50.0
    private var centPerTick: Double { maxDistanceCents / Double(centerIndex) }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<tickCount) { index in
                Rectangle()
                    .frame(width: tickWidth(forIndex: index), height: 2)
                    .cornerRadius(1)
                    .foregroundColor(colorForTick(atIndex: index))
                    .animation(.easeInOut, value: tunerData.closestNote.distance.cents)
                    .inExpandingRectangle()
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .alignmentGuide(.noteTickCenter) { d in d[HorizontalAlignment.center] }
    }

    private func tickWidth(forIndex index: Int) -> CGFloat {
        let currentError = abs(Double(tunerData.closestNote.distance.cents))
        let position = index - centerIndex

        // Base size based on distance from center tick
        let baseSize: NoteTickSize = {
            switch abs(position) {
            case 0: return .large
            case centerIndex/2, centerIndex: return .medium
            default: return .small
            }
        }()

        var width = baseSize.height
        let inTuneThres: Double = 5
        let slightlyOffThres: Double = 15

        if position == 0 {
            // Center tick adjustments
            if currentError <= inTuneThres {
                width *= 1.2
            } else if currentError > slightlyOffThres {
                width *= 0.8
            }
        } else {
            // Non-center tick adjustments
            if currentError > slightlyOffThres {
                let zone = Int(round(currentError / centPerTick))
                if abs(position - zone) <= 1 {
                    width *= 1.15
                }
            } else if currentError <= inTuneThres {
                width *= 0.9
            }
        }

        // Clamp to avoid extremes
        let minW = NoteTickSize.small.height
        let maxW = NoteTickSize.large.height * 1.25
        return max(minW, min(width, maxW))
    }

    private func colorForTick(atIndex index: Int) -> Color {
        let currentError = abs(Double(tunerData.closestNote.distance.cents))
        guard currentError <= 10 else {
            return Color.secondary.opacity(0.9)
        }

        // Calculate frequency offset for this tick
        let baseHz = tunerData.closestNote.frequency.measurement.value
        let centsOff = Double(index - centerIndex) * centPerTick
        let tickHz = baseHz * pow(2, centsOff / 1200)

        // Map to hue
        let midiFloat = 69 + 12 * log2(tickHz / 440)
        let semitone = (Int(round(midiFloat)) % 12 + 12) % 12
        let hue = Double(semitone) / 12.0
        return Color(hue: hue, saturation: 1, brightness: 1)
    }
}

/// Tick sizes for notes. `.height` drives the width in the vertical layout.
enum NoteTickSize {
    case small, medium, large
    case custom(CGFloat)

    var height: CGFloat {
        switch self {
        case .small:  return 30
        case .medium: return 90
        case .large:  return 115
        case .custom(let h): return h
        }
    }
}

extension View {
    /// Wraps in a clear rect to expand hit/test area without affecting layout.
    func inExpandingRectangle() -> some View {
        ZStack {
            Rectangle().foregroundColor(.clear)
            self
        }
    }
}


struct NoteDistanceMarkers_Previews: PreviewProvider {
    static var previews: some View {
        let makeData = { (hz: Double) -> TunerData in
            TunerData(pitch: hz, amplitude: 0.5)
        }

        Group {
            NoteDistanceMarkers(tunerData: makeData(440))
                .previewDisplayName("In Tune A4")
            NoteDistanceMarkers(tunerData: makeData(443))
                .previewDisplayName("Sharp +11.8c")
            NoteDistanceMarkers(tunerData: makeData(437))
                .previewDisplayName("Flat -11.9c")
        }
        .previewLayout(.fixed(width: 200, height: 300))
        .background(Color.gray.opacity(0.2))
    }
}
