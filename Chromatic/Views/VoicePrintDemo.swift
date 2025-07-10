//
//  VoicePrintStats.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//


import SwiftUI

struct VoicePrintStats {
    var minPitch: Double
    var maxPitch: Double
    var avgPitch: Double
    var stdDev: Double
    var uniquePitchCount: Int
    var outlierCount: Int
    var amplitude: Double
    var sessionDuration: Double
    var inTunePercent: Double
}

extension Color {
    /// Maps f₀ (avgPitch) to a hue from blue (low) to red (high)
    static func voicePrintColor(avgPitch: Double, minPitch: Double = 60, maxPitch: Double = 350, inTune: Double = 1.0, amplitude: Double = 1.0) -> Color {
        // Normalize avgPitch
        let norm = min(max((avgPitch - minPitch) / (maxPitch - minPitch), 0), 1)
        let hue = 0.9 - norm * 0.6 // 0.6 is blue, 0.0 is red on SwiftUI’s hue scale
        let saturation = 0.2 + inTune * 0.5 // Vivid if in tune
        let brightness = 0.5 + amplitude * 0.5
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

struct VoicePrintDemoView: View {
    let stats: VoicePrintStats
    @State private var animateScale = false
    @State private var animateRotation = false

    @State private var animate = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                // Background
                Circle()
                    .fill(Color.blue.opacity(0.07))
                    .frame(width: 320, height: 320)
                
                ZStack {
                    // Background
                    Circle()
                        .fill(Color.green.opacity(0.07))
                        .frame(width: 320, height: 320)
                    
                    // Animated, colored voice print shape
                    VoicePrintShape(
                        baseRadius: 100 + CGFloat((stats.avgPitch - 160) * 1.2),
                        waviness: CGFloat(stats.stdDev * 3.5),
                        lobes: max(6, stats.uniquePitchCount + stats.outlierCount),
                        inTunePercent: stats.inTunePercent / 100
                    )
                    .stroke(
                        Color.voicePrintColor(
                            avgPitch: stats.avgPitch,
                            minPitch: stats.minPitch,
                            maxPitch: stats.maxPitch,
                            inTune: stats.inTunePercent / 100,
                            amplitude: stats.amplitude
                        )
                        .opacity(0.85),
                        lineWidth: CGFloat(5 + stats.amplitude * 8)
                    )
                    .background(
                        VoicePrintShape(
                            baseRadius: 100 + CGFloat((stats.avgPitch - 160) * 1.2) - 12,
                            waviness: CGFloat(stats.stdDev * 1.5),
                            lobes: max(4, stats.uniquePitchCount),
                            inTunePercent: stats.inTunePercent / 100
                        )
                        .stroke(
                            Color.voicePrintColor(
                                avgPitch: stats.avgPitch,
                                minPitch: stats.minPitch,
                                maxPitch: stats.maxPitch,
                                inTune: stats.inTunePercent / 1,
                                amplitude: stats.amplitude * 0.7
                            )
                            .opacity(0.28),
                            lineWidth: 10
                        )
                    )
                    .frame(width: 260, height: 260)
                    .scaleEffect(animateScale ? 1.08 : 0.85)
                    .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: animateScale)
                    .rotationEffect(.degrees(animateRotation ? 360 : 0))
                    .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: animateRotation)
                    .onAppear {
                        animateScale = true
                        animateRotation = true
                    }
                    
                    // Center glow when in-tune is high
                    if stats.inTunePercent > 75 {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.55), .clear]),
                                    center: .center, startRadius: 0, endRadius: 48
                                )
                            )
                            .frame(width: 96, height: 96)
                            .opacity(0.7)
                    }
                    
                    // f₀ label
                    VStack(spacing: 2) {
                        Text("f₀")
                            .font(.system(size: 26, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                        Text("\(Int(stats.avgPitch)) Hz")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .shadow(radius: 3)
                    }
                }
                .padding(.vertical, 24)
            }

            // Summary stats
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("Session Duration:").bold()
                    Spacer()
                    Text("\(Int(stats.sessionDuration)) sec")
                }
                HStack {
                    Text("Range:").bold()
                    Spacer()
                    Text("\(Int(stats.minPitch))–\(Int(stats.maxPitch)) Hz")
                }
                HStack {
                    Text("Std Dev:").bold()
                    Spacer()
                    Text(String(format: "%.2f", stats.stdDev))
                }
                HStack {
                    Text("Unique Pitches:").bold()
                    Spacer()
                    Text("\(stats.uniquePitchCount)")
                }
                HStack {
                    Text("Amplitude:").bold()
                    Spacer()
                    Text(String(format: "%.2f", stats.amplitude))
                }
                HStack {
                    Text("In Tune:").bold()
                    Spacer()
                    Text(String(format: "%.1f", stats.inTunePercent) + "%")
                }
                HStack {
                    Text("Outliers:").bold()
                    Spacer()
                    Text("\(stats.outlierCount)")
                }
            }
            .font(.system(size: 17, weight: .regular, design: .rounded))
            .frame(width: 290)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(radius: 6, y: 2)

            Spacer()
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.04)]), startPoint: .top, endPoint: .bottom))
        .navigationTitle("Voice Print Demo")
    }
}

// MARK: - Custom Shape

struct VoicePrintShape: Shape {
    var baseRadius: CGFloat
    var waviness: CGFloat
    var lobes: Int
    var inTunePercent: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = 360
        let angleStep = (2 * .pi) / CGFloat(points)

        var path = Path()
        for i in 0..<points {
            let angle = angleStep * CGFloat(i)
            // Lobe = unique pitches; waviness = stddev
            let lobeEffect = sin(angle * CGFloat(lobes))
            // "In-tune" adds smoothness; out-of-tune increases the effect
            let smoothness = CGFloat(inTunePercent)
            let radius = baseRadius + (lobeEffect * waviness * smoothness)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    VoicePrintDemoView(stats: VoicePrintStats(
        minPitch: 77,
        maxPitch: 100,
        avgPitch: 186,
        stdDev: 3.2,
        uniquePitchCount: 8,
        outlierCount: 4,
        amplitude: 0.82,
        sessionDuration: 38.0,
        inTunePercent: 10.5
    ))
}
