import SwiftUI

struct ConcentricCircleVisualizer: View {
    let distance: Double
    let maxDistance: Double
    let tunerData: TunerData
    let fundamentalHz: Double?  // optional user-defined fundamental frequency in Hz


    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }

    private var fillColor: Color {
        let hz   = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx  = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(idx)/12.0, saturation: 1, brightness: 1)
    }
    
    /// Check if live pitch is within ±5 cents of fundamental
    private var isAtFundamental: Bool {
        guard let f0 = fundamentalHz else { return false }
        let ratio = tunerData.pitch.measurement.value / f0
        let cents = 1200 * log2(ratio)
        return abs(cents) < 10
    }

    private var startOffset: CGFloat {
        CGFloat((1 - percent) * 30)
    }

    var body: some View {
        ZStack {
            // 1) Static backdrop ring
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: CGFloat(4 + 8 * tunerData.amplitude)) // Line width based on amplitude
                .frame(width: 100, height: 100)
                .animation(.linear(duration: 0.1), value: tunerData.amplitude)

            // New WavingCircleBorder for amplitude
            WavingCircleBorder(
                strength: tunerData.amplitude * 5, // Strength based on amplitude
                frequency: 20, // A constant frequency for this effect
                lineWidth: 2,
                color: fillColor.opacity(0.1 + 0.2 * tunerData.amplitude), // Opacity based on amplitude
                animationDuration: 1,
                autoreverses: true
            )
            .frame(width: 110, height: 110) // Slightly larger to be behind other elements or distinct
            .animation(.linear(duration: 0.2), value: tunerData.amplitude)

            // 2) Two converging circles
            Group {
                Circle()
                    .fill(fillColor.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .scaleEffect(CGFloat(0.8 + 0.2 * percent)) // Scale from 0.8 to 1.0
                    .blur(radius: CGFloat(5 * (1 - percent))) // Blur from 5 to 0
                    .offset(x: -startOffset)
                    // Single animation modifier for all changes driven by percent/startOffset
                    .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: percent)


                Circle()
                    .fill(fillColor.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .scaleEffect(CGFloat(0.8 + 0.2 * percent)) // Scale from 0.8 to 1.0
                    .blur(radius: CGFloat(5 * (1 - percent))) // Blur from 5 to 0
                    .offset(x:  startOffset)
                    // Single animation modifier for all changes driven by percent/startOffset
                    .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: percent)
            }
            .blendMode(.plusLighter)

            // 3) Waving borders
            WavingCircleBorder(
                strength: 4,
                frequency: tunerData.pitch.measurement.value,
                lineWidth: 0.5 - percent,
                color: fillColor.opacity(0.3),
                animationDuration: 0.5,
                autoreverses: false
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percent)

            WavingCircleBorder(
                strength: 9,
                frequency: tunerData.pitch.measurement.value,
                lineWidth: 1 - percent,
                color: fillColor.opacity(0.3),
                animationDuration: 0.2,
                autoreverses: false
            )
            .animation(.spring(response: 1.2, dampingFraction: 0.6), value: percent)

            // 4) Glowing accents
            if percent >= 0.8 {
                WavingCircleBorder(
                    strength: isAtFundamental ? 1 : 1, // Further increased strength for exaggeration
                    frequency: tunerData.pitch.measurement.value/100,
                    lineWidth: isAtFundamental ? 1 : 3, // Further increased lineWidth for exaggeration
                    color: isAtFundamental ? .white : fillColor.opacity(0.9),
                    animationDuration: 1,
                    autoreverses: false
                )
                .animation(.easeOut(duration: 0.45), value: isAtFundamental)

                WavingCircleBorder(
                    strength: isAtFundamental ? 1 : 1, // Further increased strength for exaggeration
                    frequency: tunerData.pitch.measurement.value/20,
                    lineWidth: isAtFundamental ? 2 : 3, // Further increased lineWidth for exaggeration
                    color: isAtFundamental ? .white : fillColor.opacity(0.9),
                    animationDuration: 0.9,
                    autoreverses: false
                )
                .animation(.easeOut(duration: 0.9), value: isAtFundamental)
            }
        }
        .compositingGroup()
    }
}

struct ConcentricCircleVisualizer_Previews: PreviewProvider {
    static var tunerA4 = TunerData(pitch: 440, amplitude: 0.5)
    static var tunerC4 = TunerData(pitch: 261.6, amplitude: 0.8)

    static var previews: some View {
        VStack(spacing: 30) {
            Text("In Tune (A4)")
            ConcentricCircleVisualizer(distance:   0, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 441)

            Text("Slightly Sharp (+20¢)")
            ConcentricCircleVisualizer(distance:  20, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 460)

            Text("Slightly Flat (–9¢)")
            ConcentricCircleVisualizer(distance: -9, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 431)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
