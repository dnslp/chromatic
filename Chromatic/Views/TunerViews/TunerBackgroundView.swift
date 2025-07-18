//
//  TunerBackgroundView.swift
//  Chromatic
//
//  Created by David Nyman on 7/18/25.
//


import SwiftUI
struct TunerBackgroundView: View {
    
    // Chakra frequencies and colors
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
    let tunerData: TunerData
    let userF0: Double
    let inTuneCents: Double = 5      // +/- range considered “in tune”
    let maxCents: Double = 50        // max range for full “out of tune” color

    // The hue for this note (0...1)
    private var noteHue: Double {
        let hz   = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx  = (Int(round(midi)) % 12 + 12) % 12
        return Double(idx) / 12.0
    }

    var centsOff: Double {
        centsDistance(from: tunerData.closestNote.frequency.measurement.value, to: userF0)
    }

    // 1 when in tune, fades toward 0 as user is out of tune
    var inTunePercent: Double {
        let absOff = abs(centsOff)
        return 1.0 - min(1, max(0, (absOff - inTuneCents) / (maxCents - inTuneCents)))
    }

    // Animate both saturation and brightness: vivid and bright when in tune, dull and dim when out
    var animatedBackground: Color {
        Color(hue: noteHue,
              saturation: 0.5 + 0.5 * inTunePercent,
              brightness: 0.6 + 0.4 * inTunePercent)
    }
    
    struct AmplitudeCircleView: View {
        var amplitude: Double // 0.0 ... 1.0

        var body: some View {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: max(1, amplitude * 100)))
                .frame(width: 300, height: 300)
                .animation(.easeInOut(duration: 0.48), value: amplitude)
            
        }
    }
    

    @State private var smoothDelta: Double = 0
    let smoothingFactor = 0.0051
    let displayTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    
    struct GradientBar: View {
        var smoothDelta: Double

        var body: some View {
            let clamped = max(-50, min(50, smoothDelta))
            let percent = (clamped + 50) / 100 // 0 ... 1

            let leftHue = 0.6 - percent * 0.4 // cyan to green to red
            let rightHue = 0.6 + percent * 0.4

            let gradient = LinearGradient(
                gradient: Gradient(colors: [
                    Color(hue: leftHue, saturation: 0.9, brightness: 1),
                    Color(hue: rightHue, saturation: 0.9, brightness: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )

            return gradient
                .frame(height: 32)
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding()
                .animation(.easeInOut, value: smoothDelta)
        }
    }


    var body: some View {
        
        
        Text("Note: \(tunerData.closestNote.note.names)")
        Text("\(tunerData.closestNote.frequency.measurement.value - userF0)")
        GradientBar(smoothDelta: smoothDelta)
        TunerGradientBar(fillColor: animatedBackground, isFlat: tunerData.closestNote.distance.isFlat, isSharp: tunerData.closestNote.distance.isSharp)

            Text("Smooth Δ Closest Note: \(smoothDelta, specifier: "%.2f") Hz")
                .onReceive(displayTimer) { _ in
                    let liveDelta = tunerData.closestNote.frequency.measurement.value - userF0
                    smoothDelta += (liveDelta - smoothDelta) * smoothingFactor
                }
        

    
        ZStack {
            animatedBackground
                .animation(.easeInOut(duration: 0.88), value: animatedBackground)
                .edgesIgnoringSafeArea(.all)
            AmplitudeCircleView(amplitude: tunerData.amplitude)
            Text("\(tunerData.pitch.measurement.value - tunerData.closestNote.frequency.measurement.value))")
            WaveCircleBorder(strength: smoothDelta, frequency: 13, lineWidth: tunerData.amplitude * 40, color: .white, animationDuration: 2, autoreverses: false, height: 411, reversed: true)
            VStack {
            
                // Chakra harmonics visualization
                HStack(spacing: 1) {
                    ForEach(Array(tunerData.harmonics.prefix(7).enumerated()), id: \.offset) { idx, harmonic in
                        VStack {
                            Rectangle()
                                .fill(chakraColor(for: harmonic))
                                .frame(width: 2, height: 10)
                                .cornerRadius(4)
                            Text("\(idx+1)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .rotationEffect(.degrees(-90))
                
                
          
            }
            .foregroundColor(.white)
            .shadow(radius: 6)
        }
    }

}

