import SwiftUI

/// Visualizer showing:
///  - the current input pitch (filled circle, colored by note)
///  - the user-selected fundamental (outlined circle)
///  - the first four harmonics (small stroked circles + labels)
/// on a vertical track from `minHz`–`maxHz`.
struct PitchLineVisualizer: View {
    let tunerData: TunerData
    let frequency: Frequency
    let fundamental: Frequency?
    let minHz: Double = 55
    let maxHz: Double = 963

    /// normalized 0–1 for the live pitch
    private var percent: Double {
        let hz = frequency.measurement.value
        return min(max((hz - minHz) / (maxHz - minHz), 0), 1)
    }

    /// normalized 0–1 for f₀
    private var f0Percent: Double? {
        guard let f0 = fundamental?.measurement.value else { return nil }
        let p = (f0 - minHz) / (maxHz - minHz)
        return (0...1).contains(p) ? p : nil
    }

    /// normalized positions for harmonics 1×…4×
    private var harmonicPercents: [(multiplier: Int, percent: Double)] {
        guard let f0 = fundamental?.measurement.value else { return [] }
        return (1...4).compactMap { i in
            let freq = f0 * Double(i)
            let p = (freq - minHz) / (maxHz - minHz)
            guard (0...1).contains(p) else { return nil }
            return (i, p)
        }
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
                    .foregroundColor(.gray.opacity(0.3))

                // 2) Harmonic markers & labels
                ForEach(harmonicPercents, id: \.multiplier) { mult, p in
                    // group circle + label
                    HStack(spacing: 4) {
                        Circle()
                            .stroke(Color.primary.opacity(0.6), lineWidth: 1)
                            .frame(width: 10, height: 10)
                        Text("\(mult)x")
                            .font(.caption2)
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    // position along the track
                    .offset(x: 12, // push label to the right of the track
                            y: (1 - CGFloat(p)) * (geo.size.height - 10))
                }

                // 3) Fundamental marker (outlined)
                if let p0 = f0Percent {
                    Circle()
                        .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .offset(y: (1 - CGFloat(p0)) * (geo.size.height - 12))
                }

                // 4) Live-pitch marker (filled)
                Circle()
                    .frame(width: 16, height: 16)
                    .foregroundColor(fillColor)
                    .offset(y: (1 - CGFloat(percent)) * (geo.size.height - 16))
                    .animation(.easeInOut(duration: 0.2), value: percent)
            }
        }
        // widen a bit to fit labels
        .frame(width: 50)
    }
}


struct PitchLineVisualizer_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Example 1: f0 = 100, live = 100
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 100),
                frequency: Frequency(floatLiteral: 100),
                fundamental: Frequency(floatLiteral: 100)
            )
            .frame(height: 200)

            // Example 2: f0 = 150, live = 300
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 300),
                frequency: Frequency(floatLiteral: 300),
                fundamental: Frequency(floatLiteral: 150)
            )
            .frame(height: 200)

            // Example 3: f0 = 200, live = 80
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 80),
                frequency: Frequency(floatLiteral: 80),
                fundamental: Frequency(floatLiteral: 200)
            )
            .frame(height: 200)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
