import SwiftUI

/// Visualizer showing current input pitch position on a vertical line (55–440 Hz)
struct PitchLineVisualizer: View {
    let tunerData: TunerData
    let frequency: Frequency
    let minHz: Double = 55
    let maxHz: Double = 963

    private var percent: Double {
        let hz = frequency.measurement.value
        return min(max((hz - minHz) / (maxHz - minHz), 0), 1)
    }

    private var fillColor: Color {
        let hz   = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx  = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(idx)/12.0, saturation: 1, brightness: 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // 1) Full-height track
                Capsule()
                    .frame(width: 4, height: geo.size.height)
                    .foregroundColor(.gray)

                // 2) Circle offset from the top
                Circle()
                    .frame(width: 16, height: 16)
                    .offset(y: (1 - CGFloat(percent)) * (geo.size.height - 16))
                    .foregroundColor(fillColor)
                    .animation(.easeInOut(duration: 0.2), value: percent)
            }
        }
        .frame(width: 20)
    }
}


struct PitchLineVisualizer_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Low pitch example
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 80),
                frequency: Frequency(floatLiteral: 80)
            )
            .frame(height: 200)

            // Mid pitch example
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 220),
                frequency: Frequency(floatLiteral: 220)
            )
            .frame(height: 200)

            // High pitch example
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 400),
                frequency: Frequency(floatLiteral: 400)
            )
            .frame(height: 200)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
