import SwiftUI

// MARK: - Data Model
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

// MARK: - Color Extensions
extension Color {
    static func voicePrintColor(
        avgPitch: Double,
        minPitch: Double = 60,
        maxPitch: Double = 350,
        inTune: Double = 1.0,
        amplitude: Double = 1.0
    ) -> Color {
        let norm = min(max((avgPitch - minPitch) / (maxPitch - minPitch), 0), 1)
        let hue = 0.9 - norm * 0.6 // blue (0.6) to red (0.0)
        let saturation = 0.1 + inTune * 0.1
        let brightness = 0.2 + amplitude * 0.1
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - Hue Mapping
func hueForPitch(_ pitch: Double, minHz: Double = 65, maxHz: Double = 1046) -> Double {
    let clamped = max(minHz, min(pitch, maxHz))
    let norm = (clamped - minHz) / (maxHz - minHz)
    return 0.7 - norm * 0.7
}
func hueForPitchCircular(_ pitch: Double) -> Double {
    let midi = 69 + 12 * log2(pitch / 440)
    let noteIndex = (Int(round(midi)) + 120) % 12
    return 0.7 - (Double(noteIndex) / 12.0) * 0.7
}


// MARK: - Shape
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
            let lobeEffect = sin(angle * CGFloat(lobes))
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

func chromaColor(for pitch: Double, saturation: Double = 0.38, brightness: Double = 0.92) -> Color {
    guard pitch > 0 else { return Color.gray }
    let midi = 69 + 12 * log2(pitch / 440)
    let idx  = (Int(round(midi)) % 12 + 12) % 12
    let hue  = Double(idx) / 12.0
    return Color(hue: hue, saturation: saturation, brightness: brightness)
}


struct ChakraOverlayView: View {
    let f0: Double
    private let harmonicCount = 7
    private let chakraFrequencies: [Double] = [396, 417, 528, 639, 741, 852, 963]
    private let chakraColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple
    ]
    
    @State private var wavePhase: [Double] = Array(repeating: 0, count: 7)
    @State private var animationTimer = Timer.publish(every: 0.018, on: .main, in: .common).autoconnect()
    
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
        ZStack {
            ForEach(1...harmonicCount, id: \.self) { i in
                let harmonicFreq = f0 * Double(i)
                let color = chakraColor(for: harmonicFreq)
                WavyCircle(
                    radius: CGFloat(5 + i * 13),
                    amplitude: CGFloat(3 + i * Int(0.8)),
                    cycles: 13 + i, // more cycles on outer rings
                    phase: wavePhase[i-1]
                )
                .stroke(color.opacity(0.73), lineWidth: 4)
                .shadow(color: color.opacity(0.25), radius: 7)
                .animation(.easeInOut(duration: 0.15), value: wavePhase[i-1])
            }
        }
        .onReceive(animationTimer) { _ in
            // Animate phase for a "wobble" effect per ring
            withAnimation(.linear(duration: 0.18)) {
                for idx in 0..<wavePhase.count {
                    wavePhase[idx] += 0.08 + 0.014 * Double(idx)
                    if wavePhase[idx] > .pi * 2 { wavePhase[idx] -= .pi * 2 }
                }
            }
        }
    }
}

struct WavyCircle: Shape {
    var radius: CGFloat
    var amplitude: CGFloat
    var cycles: Int
    var phase: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = 300 // smoothness
        var path = Path()
        for i in 0...points {
            let angle = 2 * .pi * CGFloat(i) / CGFloat(points)
            let wave = sin(CGFloat(cycles) * angle + CGFloat(phase))
            let r = radius + amplitude * wave
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)
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



// MARK: - Demo View With Toggleable Hue Mapping
struct VoicePrintDemoView: View {
    let stats: VoicePrintStats
    @State private var animateScale = false
    @State private var animateRotation = false
    @State private var useChromaMapping = false

    private func colorForPitch(_ pitch: Double, amplitude: Double = 1.0, inTune: Double = 1.0) -> Color {
        let hue: Double = useChromaMapping
            ? hueForPitchCircular(pitch)
            : hueForPitch(pitch)
        let saturation = 0.5 + inTune * 0.5
        let brightness = 0.5 + amplitude * 0.5
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var body: some View {
        VStack(spacing: 24) {
 

            ZStack {
                ChakraOverlayView(f0: stats.avgPitch)
                // Background mist
                Circle()
                    .fill(
                        chromaColor(for: stats.avgPitch, saturation: 0.17, brightness: 0.97)
                            .opacity(0.08)
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: animateScale ? 8 : 4)
                    .scaleEffect(animateScale ? 1.08 : 0.98)
                    .animation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true), value: animateScale)

                // Outer glowing ring
                Circle()
                    .stroke(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                chromaColor(for: stats.avgPitch, saturation: 0.5, brightness: 1).opacity(0.18),
                                chromaColor(for: stats.avgPitch, saturation: 0.32, brightness: 0.95).opacity(0.04)
                            ]),
                            center: .center,
                            startRadius: 40,
                            endRadius: 200
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 272, height: 272)
                    .blur(radius: 8)
                    .opacity(animateScale ? 0.72 : 0.36)
                    .scaleEffect(animateScale ? 1.04 : 0.97)
                    .animation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true), value: animateScale)

                // Main animated voice print shape
                VoicePrintShape(
                    baseRadius: 80 + CGFloat(stats.amplitude * 78),
                    waviness: max(2, CGFloat(stats.stdDev * 0.25)),
                    lobes: max(5, stats.uniquePitchCount / 2 + stats.outlierCount / 2),
                    inTunePercent: 1.0 - (stats.inTunePercent / 100)
                )
                .stroke(
                    chromaColor(for: stats.avgPitch, saturation: 0.38, brightness: 0.89)
                        .opacity(0.81),
                    lineWidth: 4
                )
                .frame(width: 238, height: 238)
                .rotationEffect(.degrees(animateRotation ? 360 : 0))
                .shadow(
                    color: chromaColor(for: stats.avgPitch, saturation: 0.46, brightness: 0.99).opacity(0.23),
                    radius: 16, y: 6
                )
                .animation(.linear(duration: 13.5).repeatForever(autoreverses: false), value: animateRotation)
                .onAppear {
                    animateScale = true
                    animateRotation = true
                }

                // Inner animated shape, faster/less intense
                VoicePrintShape(
                    baseRadius: 120,
                    waviness: 7,
                    lobes: max(13, stats.uniquePitchCount / 4),
                    inTunePercent:  1.0 - (stats.inTunePercent / 100)
                )
                .stroke(
                    chromaColor(for: stats.avgPitch, saturation: 0.32, brightness: 0.80)
                        .opacity(0.51),
                    lineWidth: 2
                )
                .frame(width: 148, height: 148)
                .rotationEffect(.degrees(animateRotation ? -360 : 0))
                .animation(.linear(duration: 17).repeatForever(autoreverses: false), value: animateRotation)

                // Center chromatic glow (when in tune)
                if stats.inTunePercent > 75 {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    chromaColor(for: stats.avgPitch, saturation: 0.33, brightness: 1.0).opacity(0.45),
                                    .clear
                                ]),
                                center: .center, startRadius: 0, endRadius: 48
                            )
                        )
                        .frame(width: 98, height: 98)
                        .opacity(0.72)
                    
                }
                

                // f₀ label
                
                VStack(spacing: 2) {
                    Text("f₀")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                    Text("\(Int(stats.avgPitch)) Hz")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .shadow(color: chromaColor(for: stats.avgPitch, saturation: 0.34, brightness: 0.97).opacity(0.28), radius: 8)
                }
                .padding(.top, 360)
            }
            .padding(.vertical, 24)

            // Stats summary, unchanged
            VStack(alignment: .leading, spacing: 2) {
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
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .frame(width: 220)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
            .shadow(radius: 6, y: 2)

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    chromaColor(for: stats.avgPitch, saturation: 0.14, brightness: 0.99).opacity(0.04),
                    Color.purple.opacity(0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Voice Print Demo")
    }

}

        
        #Preview {
            VoicePrintDemoView(stats: VoicePrintStats(
                minPitch: 170,
                maxPitch: 110,
                avgPitch: 117,
                stdDev: 10.2,
                uniquePitchCount: 10,
                outlierCount: 18,
                amplitude: 0.7,
                sessionDuration: 17.0,
                inTunePercent: 20.5
                
                
            ))
        }
    
