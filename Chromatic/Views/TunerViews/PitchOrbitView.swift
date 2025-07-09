//
//  PitchOrbitView.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//


import SwiftUI

struct PitchOrbitView: View {
    let liveHz: Double
    let f0: Double
    let fourth: Double
    let fifth: Double
    let harmonics: [Double]
    
    private func angle(for freq: Double) -> Angle {
        // One octave (1200 cents) = 360 degrees
        guard f0 > 0, freq > 0 else { return .degrees(0) }
        let cents = 1200 * log2(freq / f0)
        return .degrees(cents / 1200 * 360)
    }
    
    var body: some View {
        ZStack {
            // Main orbit
            Circle()
                .stroke(Color.gray.opacity(0.18), lineWidth: 48)
                .frame(width: 260, height: 260)
            
            // f₀ anchor
            Circle()
                .fill(Color.blue)
                .frame(width: 26, height: 26)
                .offset(y: -130)
                .overlay(Text("f₀").font(.caption2).foregroundColor(.white).offset(y: -18))
            
            // Perfect 4th
            Circle()
                .fill(Color.green)
                .frame(width: 20, height: 20)
                .offset(angle: angle(for: fourth), radius: 130)
                .overlay(Text("P4").font(.caption2).foregroundColor(.white).offset(x: 0, y: -18))
            
            // Perfect 5th
            Circle()
                .fill(Color.orange)
                .frame(width: 20, height: 20)
                .offset(angle: angle(for: fifth), radius: 130)
                .overlay(Text("P5").font(.caption2).foregroundColor(.white).offset(x: 0, y: -18))
            
            // Harmonics
            ForEach(Array(harmonics.prefix(4).enumerated()), id: \.offset) { i, hz in
                Circle()
                    .fill(Color.purple.opacity(0.55))
                    .frame(width: 14, height: 14)
                    .offset(angle: angle(for: hz), radius: 130)
                    .overlay(Text("f\(i+2)").font(.caption2).foregroundColor(.white).offset(y: -14))
            }
            
            // Live pitch
            Circle()
                .stroke(Color.red, lineWidth: 6)
                .frame(width: 36, height: 36)
                .offset(angle: angle(for: liveHz), radius: 130)
                .overlay(
                    VStack {
                        Text(String(format: "%.1f Hz", liveHz))
                            .font(.caption.bold())
                            .foregroundColor(.red)
                        Text("\(Int(1200 * log2(liveHz / f0)))¢")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .offset(y: -38)
                )
        }
        .frame(width: 300, height: 300)
    }
}

// Extension for positioning around a circle
extension View {
    func offset(angle: Angle, radius: CGFloat) -> some View {
        let radians = CGFloat(angle.radians - .pi/2) // Rotate so 0 is top
        return self.offset(
            x: cos(radians) * radius,
            y: sin(radians) * radius
        )
    }
}
