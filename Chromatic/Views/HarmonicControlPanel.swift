//
//  HarmonicControlPanel.swift
//  Chromatic
//
//  Created by David Nyman on 7/6/25.
//


import SwiftUI

struct HarmonicControlPanel: View {
    @StateObject private var tonePlayer = TonePlayer()
    @State private var amplitudes = HarmonicAmplitudes()
    @State private var frequency: Double = 220.0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Harmonic Mixer")
                .font(.headline)
            SliderRow(label: "Fundamental", value: $amplitudes.fundamental, range: 0...1)
            SliderRow(label: "2nd Harmonic", value: $amplitudes.harmonic2, range: 0...0.5)
            SliderRow(label: "3rd Harmonic", value: $amplitudes.harmonic3, range: 0...0.5)
            SliderRow(label: "Formant (1200 Hz)", value: $amplitudes.formant, range: 0...0.5)
            
            HStack {
                Text("Frequency: \(Int(frequency)) Hz")
                Slider(value: $frequency, in: 110...880, step: 1)
            }
            
            Button("Play Tone") {
                tonePlayer.play(frequency: frequency, duration: 1.2, amplitudes: amplitudes)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            Slider(value: $value, in: range)
            Text(String(format: "%.2f", value))
                .frame(width: 44, alignment: .trailing)
        }
    }
}
