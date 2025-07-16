//
//  BareConcentricCircleView.swift
//  Chromatic
//
//  Created by David Nyman on 7/16/25.
//


import SwiftUI

struct BareConcentricCircleView: View {
    /// How far off you are (in cents), and the maximum you’ll visualize.
    let distance: Double
    let maxDistance: Double

    /// Your tuner state (for amplitude or pitch if you want to add it later).
    let tunerData: TunerData
    
    private var fillColor: Color {
        let hz   = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx  = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(idx)/12.0, saturation: 1, brightness: 1)
    }

    /// Optional f₀ override.
    let fundamentalHz: Double?

    /// 0…1 based on how close `distance` is to zero.
    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }

    /// Which freq to use as the center reference.
    private var f0: Double {
        fundamentalHz ?? tunerData.pitch.measurement.value
    }

    /// Raw Hz difference, as a fallback label.
    private var freqDifference: Double {
        tunerData.pitch.measurement.value - f0
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth: CGFloat = size * 0.1

            ZStack {
                // 1) Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

                // 2) Progress ring (green-to-red based on percent)
                Circle()
                    .trim(from: 0, to: CGFloat(percent))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [fillColor, .white, fillColor]),
                            center: .center,
                            startAngle: .degrees(90),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // 3) Center label: either “f₀” or raw Hz diff
                Text(fundamentalHz != nil ? "f₀" : "\(Int(freqDifference)) Hz")
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct BareConcentricCircleView_Previews: PreviewProvider {
    static var tunerA4 = TunerData(pitch: 440, amplitude: 0.5)
    static var tunerC4 = TunerData(pitch: 261.6, amplitude: 0.8)

    static var previews: some View {
        VStack(spacing: 40) {
            Text("In Tune (A4)")
            BareConcentricCircleView(
                distance:   0,
                maxDistance: 50,
                tunerData: tunerA4,
                fundamentalHz: 440
            )
            .frame(width: 180, height: 180)

            Text("Slightly Sharp (+20¢)")
            BareConcentricCircleView(
                distance:  20,
                maxDistance: 50,
                tunerData: tunerA4,
                fundamentalHz: 440
            )
            .frame(width: 180, height: 180)

            Text("No Fundamental Set")
            BareConcentricCircleView(
                distance: -30,
                maxDistance: 50,
                tunerData: tunerC4,
                fundamentalHz: nil
            )
            .frame(width: 180, height: 180)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
