import SwiftUI

/// A horizontal marker bar that moves vertically over a vertical tick stack.
struct CurrentNoteMarker: View {
    let frequency: Frequency
    let distance: Frequency.MusicalDistance
    let showFrequencyText: Bool

    // Base constants for the horizontal bar
    private let baseLength: CGFloat    = 100   // Length across ticks when perfectly in tune
    private let baseThickness: CGFloat = 15     // Thickness when perfectly in tune
    private let totalWidth: CGFloat    = 120   // Overall view width
    private let maxDistance: Double    = 50    // Max cents to map to extremes

    // Animation driver for the glow
    @State private var glowOn = false

    // MARK: 1) Compute the fill hue from note name
    private var fillColor: Color {
        let hz = frequency.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let semitone = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(semitone)/12.0, saturation: 1, brightness: 1)
    }

    // MARK: 2) Compute glow color & intensity based on cent deviation
    private var glowColor: Color {
        let cents = abs(Double(distance.cents))
        switch cents {
        case ...5:   return fillColor.opacity(0.8)
        case ...15:  return fillColor.opacity(0.6)
        case ...30:  return fillColor.opacity(0.2)
        default:     return .white
        }
    }

    // MARK: 3) Compute dynamic thickness that shrinks out-of-tune
    private var dynamicThickness: CGFloat {
        let error = min(abs(Double(distance.cents)), maxDistance)
        let factor = 1 - 0.5 * (error / maxDistance)
        return baseThickness * CGFloat(factor)
    }

    // MARK: 4) Exaggerated vertical position mapping ±50c to full height
    private var verticalPercent: CGFloat {
        // Clamp error
        let error = min(max(Double(distance.cents), -maxDistance), maxDistance)
        let normalized = error / maxDistance            // -1 ... +1
        // Map to 0 ... 1, with -1→1 (bottom), +1→0 (top)
        return CGFloat(0.5 - (normalized * 0.5))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Invisible expander
                Color.clear
                    .frame(width: totalWidth, height: geo.size.height)

                // Horizontal marker bar
                Rectangle()
                    .frame(width: baseLength, height: dynamicThickness)
                    .cornerRadius(dynamicThickness / 2)
                    .foregroundColor(fillColor.opacity(distance.isPerceptible ? 1 : 0.6))
                    .shadow(
                        color: glowColor.opacity(glowOn ? 1.0 : 0.3),
                        radius: glowOn ? 20 : 10
                    )
                    .animation(.easeInOut(duration: 0.9), value: distance.cents)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                        ) {
                            glowOn.toggle()
                        }
                    }
                    .position(
                        x: totalWidth / 2,
                        y: geo.size.height * verticalPercent
                    )
            }

            // Optional frequency text below marker
            if showFrequencyText {
                Text(frequency.localizedString())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .offset(y: geo.size.height + 8)
            }
        }
        .frame(
            width: totalWidth,
            height: baseThickness + (showFrequencyText ? 30 : 0)
        )
        .alignmentGuide(.noteTickCenter) { d in d[HorizontalAlignment.center] }
    }
}

struct CurrentNoteMarker_Previews: PreviewProvider {
    static var previews: some View {
        let makeDist: (Double) -> Frequency.MusicalDistance = { Frequency.MusicalDistance(cents: Float($0)) }
        Group {
            CurrentNoteMarker(
                frequency: Frequency(floatLiteral: 440),
                distance: makeDist(0),
                showFrequencyText: true
            )
            .previewDisplayName("In Tune")

            CurrentNoteMarker(
                frequency: Frequency(floatLiteral: 442),
                distance: makeDist(30),
                showFrequencyText: true
            )
            .previewDisplayName("Sharp +30c")

            CurrentNoteMarker(
                frequency: Frequency(floatLiteral: 437),
                distance: makeDist(-30),
                showFrequencyText: true
            )
            .previewDisplayName("Flat -30c")
        }
        .frame(width: 200, height: 300)
        .background(Color.gray.opacity(0.1))
    }
}
