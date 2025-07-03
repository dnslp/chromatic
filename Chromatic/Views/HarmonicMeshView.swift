//
//  HarmonicMeshView.swift
//  Chromatic
//
//  Created by David Nyman on 7/3/25.
//


import SwiftUI

/// A mesh-style visualization plotting each harmonic’s amplitude and cent distance on a grid.
struct HarmonicMeshView: View {
    /// The full tuner data (pitch, amplitude, closestNote)
    let tunerData: TunerData
    private let harmonicCount = 7
    private let gridRows = 5

    // Extract fundamental and compute harmonics
    private var f0Hz: Double { tunerData.pitch.measurement.value }
    private var harmonics: [Double] { (1...harmonicCount).map { Double($0) * f0Hz } }
    // Amplitude (0...1)
    private var amplitude: Double { tunerData.amplitude }
    // Cent distance in cents
    private var centOffset: Double { Double(tunerData.closestNote.distance.cents) }

    var body: some View {
        GeometryReader { geo in
            let cols = harmonicCount
            let rows = gridRows
            let cellW = geo.size.width / CGFloat(cols)
            let cellH = geo.size.height / CGFloat(rows)

            ZStack {
                // Vertical grid lines
                ForEach(0...cols, id: \.self) { col in
                    Path { path in
                        let x = CGFloat(col) * cellW
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                }
                // Horizontal grid lines
                ForEach(0...rows, id: \.self) { row in
                    Path { path in
                        let y = CGFloat(row) * cellH
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                }

                // Plot harmonic points
                ForEach(Array(harmonics.enumerated()), id: \.offset) { idx, freq in
                    let x = CGFloat(idx) * cellW + cellW / 2
                    // Amplitude dot (higher amplitude = higher on screen)
                    let yAmp = geo.size.height * (1 - CGFloat(amplitude))
                    Circle()
                        .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .position(x: x, y: yAmp)

                    // Cent-offset marker around center line
                    let midY = geo.size.height / 2
                    let yCent = midY + CGFloat(centOffset / 50) * cellH
                    Rectangle()
                        .fill(tunerData.closestNote.distance.isSharp ? Color.red : Color.green)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: yCent)
                }
            }
        }
        .padding(8)
    }
}

// MARK: - Usage in TunerView.swift
/*
HarmonicMeshView(tunerData: tunerData)
    .frame(height: 120)
    .padding(.horizontal)
*/
