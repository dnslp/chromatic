import SwiftUI
import Foundation



struct ConcentricCircleVisualizer: View {
    let distance: Double       // Pitch deviation in cents
    let maxDistance: Double    // Full-scale error for 0…1 percent
    let tunerData: TunerData



    /// 0…1 how “in tune” you are
    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }

    /// Color hue based on semitone (C→B)
    private var fillColor: Color {
        let hz   = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx  = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(idx)/12.0, saturation: 1, brightness: 1)
    }

    /// How far apart to start the circles (they converge as percent→1)
    private var startOffset: CGFloat {
        CGFloat((1 - percent) * 50)  // max ±50 points
    }

    var body: some View {
        ZStack {
            // 1) Static backdrop ring
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                .frame(width: 100, height: 100)

            // 2) Two additive‐blend circles converging toward center
            ZStack {
                Circle()
                    .fill(fillColor.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .offset(x: -startOffset)
                Circle()
                    .fill(fillColor.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .offset(x:  startOffset)
                WavingCircleBorder(
                    strength: 4,
                    frequency: tunerData.pitch.measurement.value,
                    lineWidth: 0.5 - percent,
                    color: fillColor.opacity(0.3),
                    animationDuration: 0.9,
                    autoreverses: false
                )
                WavingCircleBorder(
                    strength: 9,
                    frequency: tunerData.pitch.measurement.value,
                    lineWidth: 1 - percent,
                    color: fillColor.opacity(0.3),
                    animationDuration: 2,
                    autoreverses: false
                )
            }
            .blendMode(.plusLighter)
            .animation(.easeInOut(duration: 0.5), value: percent)

            // 3) Glowing border when within ±10 cents (percent ≥ .8)
            if percent >= 0.8 {
                // Default green 110×110 waving border
       

                // Softer, faster red wave
                WavingCircleBorder(
                    strength: 3,
                    frequency: (tunerData.pitch.measurement.value/3),
                    lineWidth: percent,
                    color: fillColor.opacity(0.9),
                    animationDuration: 0.45,
                    autoreverses: false
                )
                WavingCircleBorder(
                    strength: 4,
                    frequency: (tunerData.pitch.measurement.value/2),
                    lineWidth: percent,
                    color: fillColor.opacity(0.9),
                    animationDuration: 0.9,
                    autoreverses: false
                )

            }
        }
        .compositingGroup()  // ensure blendMode works correctly
    }
}


struct ConcentricCircleVisualizer_Previews: PreviewProvider {
    static var tunerA4 = TunerData(pitch: 440, amplitude: 0.5)
    static var tunerC4 = TunerData(pitch: 261.6, amplitude: 0.8)

    static var previews: some View {
        VStack(spacing: 30) {
            Text("In Tune (A4)")
            ConcentricCircleVisualizer(distance:   0, maxDistance: 50, tunerData: tunerA4)

            Text("Slightly Sharp (+20¢)")
            ConcentricCircleVisualizer(distance:  20, maxDistance: 50, tunerData: tunerA4)

            Text("Slightly Flat (–20¢)")
            ConcentricCircleVisualizer(distance: -3, maxDistance: 50, tunerData: tunerA4)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
