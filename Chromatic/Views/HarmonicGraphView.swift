import SwiftUI

struct HarmonicGraphView: View {
    let tunerData: TunerData
    private let harmonicCount = 7

    // Chakra frequencies and colors
    private let chakraFrequencies: [Double] = [396, 417, 528, 639, 741, 852, 963]
    private let chakraColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple
    ]

    private var f0Hz: Double { tunerData.pitch.measurement.value }
    private var harmonics: [Double] {
        (1...harmonicCount).map { Double($0) * f0Hz }
    }
    private func chakraColor(for freq: Double) -> Color {
        let idx = chakraFrequencies
            .enumerated()
            .min(by: { abs($0.element - freq) < abs($1.element - freq) })!
            .offset
        return chakraColors[idx]
    }

    var body: some View {
        GeometryReader { geo in
            let maxFreq = harmonics.max() ?? 1
            let height = geo.size.height
            let width: CGFloat = 24
            // Gradient stops for vertical layout
            let stops: [Gradient.Stop] = harmonics.map { freq in
                let loc = freq / maxFreq
                return Gradient.Stop(color: chakraColor(for: freq).opacity(0.8), location: loc)
            }
            ZStack(alignment: .leading) {
                // Vertical gradient bar (bottom = low, top = high)
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: stops),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: width)

                // Chakra markers & labels
//                ForEach(Array(chakraFrequencies.enumerated()), id: \.offset) { idx, freq in
//                    let yPos = height - CGFloat(freq / maxFreq) * height
//                    // Horizontal tick
//                    Path { path in
//                        path.move(to: CGPoint(x: 0, y: yPos))
//                        path.addLine(to: CGPoint(x: width, y: yPos))
//                    }
//                    .stroke(chakraColors[idx].opacity(0.2), lineWidth: 1)
//
//                    // Upright Hz label to right of tick
//                    Text("\(Int(freq)) Hz")
//                        .font(.system(size: 7))
//                        .foregroundColor(chakraColors[idx])
//                        .position(x: 12, y: yPos)
//                        // Optionally add .rotationEffect(.degrees(0)) to keep upright
//                }
            }
            .frame(width: width + 3)
        }
        .frame(width: 48, height: 240) // Tall and narrow
    }
}

// MARK: - Preview
struct HarmonicGraphView_Previews: PreviewProvider {
    static var previews: some View {
        HarmonicGraphView(tunerData: TunerData(pitch: 150, amplitude: 0.5))
            .padding()
            .previewLayout(.fixed(width: 80, height: 300))
    }
}
