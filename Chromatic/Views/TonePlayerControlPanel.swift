//
//  TonePlayerControlPanel.swift
//  Chromatic
//
//  Created by David Nyman on 7/8/25.
//


import SwiftUI

struct VowelPreset: Identifiable {
    let id = UUID()
    let name: String
    let amplitudes: HarmonicAmplitudes
}

let vowelPresets: [VowelPreset] = [
    VowelPreset(name: "A (as in 'father')", amplitudes: HarmonicAmplitudes(fundamental: 0.85, harmonic2: 0.16, harmonic3: 0.08, formant: 0.44, noise: 0.00)),
    VowelPreset(name: "E (as in 'bed')",    amplitudes: HarmonicAmplitudes(fundamental: 0.75, harmonic2: 0.15, harmonic3: 0.06, formant: 0.33, noise: 0.01)),
    VowelPreset(name: "I (as in 'machine')",amplitudes: HarmonicAmplitudes(fundamental: 0.67, harmonic2: 0.19, harmonic3: 0.13, formant: 0.18, noise: 0.01)),
    VowelPreset(name: "O (as in 'law')",    amplitudes: HarmonicAmplitudes(fundamental: 0.77, harmonic2: 0.18, harmonic3: 0.09, formant: 0.27, noise: 0.00)),
    VowelPreset(name: "U (as in 'goose')",  amplitudes: HarmonicAmplitudes(fundamental: 0.83, harmonic2: 0.13, harmonic3: 0.09, formant: 0.21, noise: 0.00)),
    VowelPreset(name: "Breathy",            amplitudes: HarmonicAmplitudes(fundamental: 0.55, harmonic2: 0.09, harmonic3: 0.03, formant: 0.07, noise: 0.13)),
    VowelPreset(name: "Whisper",            amplitudes: HarmonicAmplitudes(fundamental: 0.1, harmonic2: 0.01, harmonic3: 0.01, formant: 0.04, noise: 0.49))
]


struct TonePlayerControlPanel: View {
    @State private var frequency: Double = 220
    @State private var duration: Double = 1.2
    @State private var attack: Double = 0.04
    @State private var release: Double = 0.12
    @State private var harmonicAmplitudes = HarmonicAmplitudes()
    @StateObject private var tonePlayer = TonePlayer()
    @State private var playing = false
    @State private var selectedPreset: VowelPreset? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // ───── Vowel Presets ─────
                Text("Vowel-like Presets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vowelPresets) { preset in
                            Button(action: {
                                self.harmonicAmplitudes = preset.amplitudes
                                self.selectedPreset = preset
                            }) {
                                Text(preset.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedPreset?.id == preset.id ? Color.accentColor.opacity(0.29) : Color.secondary.opacity(0.09))
                                    .cornerRadius(7)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                // ───── Sound Controls ─────
                Group {
                    SliderRow(label: "Frequency", value: $frequency, range: 80...880, format: "%.1f Hz")
                    SliderRow(label: "Duration", value: $duration, range: 0.2...2.5, format: "%.2f s")
                    SliderRow(label: "Attack", value: $attack, range: 0.01...0.15, format: "%.2f s")
                    SliderRow(label: "Release", value: $release, range: 0.03...0.3, format: "%.2f s")
                }
                
                Divider().padding(.vertical, 3)
                
                // ───── Harmonic/Noise Sliders ─────
                Group {
                    SliderRow(label: "Fundamental", value: $harmonicAmplitudes.fundamental, range: 0...1)
                    SliderRow(label: "2nd Harmonic", value: $harmonicAmplitudes.harmonic2, range: 0...1)
                    SliderRow(label: "3rd Harmonic", value: $harmonicAmplitudes.harmonic3, range: 0...1)
                    SliderRow(label: "Formant (1200 Hz)", value: $harmonicAmplitudes.formant, range: 0...1)
                    SliderRow(label: "Noise", value: $harmonicAmplitudes.noise, range: 0...0.5)
                }
            }
            .padding(.bottom, 16) // So Play button doesn't overlap with the scroll end
        }
        // Play button always visible at the bottom
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                tonePlayer.play(
                    frequency: frequency,
                    duration: duration,
                    amplitudes: harmonicAmplitudes,
                    attack: attack,
                    release: release
                )
                playing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    playing = false
                }
            }) {
                Label(playing ? "Playing..." : "Play", systemImage: playing ? "waveform" : "play.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(playing ? Color.green.opacity(0.3) : Color.accentColor.opacity(0.17))
                    .cornerRadius(14)
            }
            .disabled(playing)
            .padding()
            .background(BlurView(style: .systemMaterialDark).ignoresSafeArea()) // Nice effect on iOS
        }
        .padding(.horizontal)
        .animation(.default, value: harmonicAmplitudes)
    }
}

// --- Helper Slider Row ---
fileprivate struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.2f"
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                Spacer()
                Text(String(format: format, value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}

// --- Optional: Blur background for bottom sheet ---
#if canImport(UIKit)
import UIKit
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#else
struct BlurView: View { var style: Any; var body: some View { Color.clear } }
#endif

// MARK: - Preview
struct TonePlayerControlPanel_Previews: PreviewProvider {
    static var previews: some View {
        TonePlayerControlPanel()
            .frame(width: 370)
            .preferredColorScheme(.dark)
    }
}
