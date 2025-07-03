import SwiftUI

/// A continuous harmonic gradient showing f₀ through the 6th harmonic,
/// colored by the nearest chakra frequency at each position.
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
            // Build gradient stops based on harmonic positions
            let stops: [Gradient.Stop] = harmonics.map { freq in
                let loc = freq / maxFreq
                return Gradient.Stop(color: chakraColor(for: freq).opacity(0.8), location: loc)
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: stops),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 20)
        }
        .frame(height: 20)
    }
}

// MARK: - Usage in TunerView.swift
/*
HarmonicGradientView(tunerData: tunerData)
    .frame(height: 24)
    .padding(.horizontal)
*/
