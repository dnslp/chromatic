import SwiftUI

/// A continuous harmonic gradient showing f₀ through the 6th harmonic,
/// colored by the nearest chakra frequency at each position,
/// with vertical markers and sideways Hz labels next to each line.
struct HarmonicGraphView: View {
    /// Full tuner data to extract the fundamental pitch
    let tunerData: TunerData
    private let harmonicCount = 7  // f₀ through 6th harmonic

    // Chakra frequencies and colors
    private let chakraFrequencies: [Double] = [396, 417, 528, 639, 741, 852, 963]
    private let chakraColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple
    ]

    /// Fundamental pitch in Hz
    private var f0Hz: Double { tunerData.pitch.measurement.value }

    /// All harmonic frequencies
    private var harmonics: [Double] {
        (1...harmonicCount).map { Double($0) * f0Hz }
    }

    /// Determine chakra color for a given frequency
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
            let width = geo.size.width
            let height: CGFloat = 24
            // Build gradient stops based on harmonic positions
            let stops: [Gradient.Stop] = harmonics.map { freq in
                let loc = freq / maxFreq
                return Gradient.Stop(color: chakraColor(for: freq).opacity(0.8), location: loc)
            }

            ZStack(alignment: .topLeading) {
                // Gradient bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: stops),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: height + 2)

                // Chakra markers with sideways labels
                ForEach(Array(chakraFrequencies.enumerated()), id: \.offset) { idx, freq in
                    let xPos = CGFloat(freq / maxFreq) * width
                    // Vertical tick
                    Path { path in
                        path.move(to: CGPoint(x: xPos, y: 0))
                        path.addLine(to: CGPoint(x: xPos, y: height))
                    }
                    .stroke(chakraColors[idx].opacity(0.8), lineWidth: 1)
                    
                    // Sideways Hz label
                    Text("\(Int(freq)) Hz")
                        .font(.system(size: 7))
                        .foregroundColor(chakraColors[idx])
                        .rotationEffect(.degrees(-90))
                        // position label to right of tick and centered vertically
                        .position(x: xPos + 12, y: height / 2)
                }
            }
            .frame(height: height + 0)
        }
        .frame(height: 48)
    }
}

// MARK: - Preview
struct HarmonicGraphView_Previews: PreviewProvider {
    static var previews: some View {
        HarmonicGraphView(tunerData: TunerData(pitch: 150, amplitude: 0.5))
            .padding()
            .previewLayout(.fixed(width: 300, height: 80))
    }
}

// MARK: - Usage in TunerView.swift
/*
HarmonicGradientView(tunerData: tunerData)
    .frame(height: 60)
    .padding(.horizontal)
*/
