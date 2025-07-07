import SwiftUI

struct PitchChakraTimelineView: View {
    let pitches: [Double]
    private let harmonicCount = 7
    private let chakraFrequencies: [Double] = [396, 417, 528, 639, 741, 852, 963]
    private let chakraColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple
    ]

    private func chakraColor(for freq: Double) -> Color {
        guard freq > 0 else { return .gray }
        var minDiff = Double.greatestFiniteMagnitude
        var idx = 0
        for (i, f) in chakraFrequencies.enumerated() {
            let diff = abs(f - freq)
            if diff < minDiff {
                minDiff = diff
                idx = i
            }
        }
        return chakraColors[idx]
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let count = pitches.count
            let barWidth = count > 0 ? width / CGFloat(count) : width
            let minPitch = pitches.filter { $0 > 0 }.min() ?? 80
            let maxPitch = pitches.max() ?? 880
            let denom = max(1, maxPitch - minPitch)

            Canvas { context, size in
                if count == 0 { return } // guard against empty pitch array
                for col in 0..<count {
                    let basePitch = pitches[col]
                    if basePitch <= 0 { continue }
                    for harmonic in 1...harmonicCount {
                        let harmonicFreq = Double(harmonic) * basePitch
                        let color = chakraColor(for: harmonicFreq)
                        let x = CGFloat(col) * barWidth
                        // For vertical stack: bottom = fundamental, top = 7th harmonic
                        let hFrac = CGFloat(harmonic-1) / CGFloat(harmonicCount)
                        let nextFrac = CGFloat(harmonic) / CGFloat(harmonicCount)
                        let yStart = height * (1.0 - nextFrac)
                        let yEnd = height * (1.0 - hFrac)
                        let rect = CGRect(x: x, y: yStart, width: barWidth, height: yEnd - yStart)
                        let opacity = 0.35 + 0.55 * (1 - Double(harmonic-1)/Double(harmonicCount-1))
                        context.fill(Path(rect), with: .color(color.opacity(opacity)))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(height: 48)
        .padding(.vertical, 2)
    }
}

struct PitchChakraTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        PitchChakraTimelineView(
            pitches: (0..<128).map { i in
                220 + 110 * sin(Double(i)/18.0) + Double.random(in: -7...7)
            }
        )
        .frame(width: 320, height: 48)
        .padding()
    }
}
