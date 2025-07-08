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

// Updated Vowel Presets to include new parameters
let vowelPresets: [VowelPreset] = [
    VowelPreset(name: "A (as in 'father')", amplitudes: .init(fundamental: 0.85, harmonic2: 0.16, harmonic3: 0.08, formant: 0.18, noiseLevel: 0.00, formantFrequency: 900, waveform: .sine, noiseType: .white, eqLowGain: 0, eqMidGain: 0, eqHighGain: 0)),
    VowelPreset(name: "E (as in 'bed')",    amplitudes: .init(fundamental: 0.75, harmonic2: 0.15, harmonic3: 0.06, formant: 0.11, noiseLevel: 0.01, formantFrequency: 1100, waveform: .sine, noiseType: .white, eqLowGain: 0, eqMidGain: 0, eqHighGain: 0)),
    VowelPreset(name: "I (as in 'machine')",amplitudes: .init(fundamental: 0.67, harmonic2: 0.19, harmonic3: 0.13, formant: 0.09, noiseLevel: 0.01, formantFrequency: 1200, waveform: .sine, noiseType: .white, eqLowGain: 0, eqMidGain: 0, eqHighGain: 0)),
    VowelPreset(name: "O (as in 'law')",    amplitudes: .init(fundamental: 0.77, harmonic2: 0.18, harmonic3: 0.09, formant: 0.12, noiseLevel: 0.00, formantFrequency: 800, waveform: .sine, noiseType: .white, eqLowGain: 0, eqMidGain: 0, eqHighGain: 0)),
    VowelPreset(name: "U (as in 'goose')",  amplitudes: .init(fundamental: 0.83, harmonic2: 0.13, harmonic3: 0.09, formant: 0.07, noiseLevel: 0.00, formantFrequency: 850, waveform: .sine, noiseType: .white, eqLowGain: 0, eqMidGain: 0, eqHighGain: 0)),
    VowelPreset(name: "Breathy",            amplitudes: .init(fundamental: 0.55, harmonic2: 0.09, harmonic3: 0.03, formant: 0.04, noiseLevel: 0.13, formantFrequency: 900, waveform: .sine, noiseType: .pink, eqLowGain: 0, eqMidGain: -2, eqHighGain: 1)),
    VowelPreset(name: "Whisper",            amplitudes: .init(fundamental: 0.10, harmonic2: 0.01, harmonic3: 0.01, formant: 0.02, noiseLevel: 0.49, formantFrequency: 1200, waveform: .sine, noiseType: .white, eqLowGain: 0, eqMidGain: 0, eqHighGain: 2))
]

struct TonePlayerControlPanel: View {
    @EnvironmentObject private var settings: ToneSettingsManager
    @State private var frequency: Double = 220
    @State private var duration: Double = 1.2
    @StateObject private var tonePlayer = TonePlayer()
    @State private var playing = false
    @State private var selectedPreset: VowelPreset?

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
                                settings.amplitudes = preset.amplitudes
                                selectedPreset = preset
                            }) {
                                Text(preset.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedPreset?.id == preset.id
                                          ? Color.accentColor.opacity(0.29)
                                          : Color.secondary.opacity(0.09)
                                    )
                                    .cornerRadius(7)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                // ───── Sound Controls ─────
                Group {
                    SliderRow(label: "Frequency",
                              value: $frequency,
                              range: 80...880,
                              format: "%.1f Hz")
                    SliderRow(label: "Duration",
                              value: $duration,
                              range: 0.2...2.5,
                              format: "%.2f s")
                    SliderRow(label: "Attack",
                              value: $settings.attack,
                              range: 0.01...0.15,
                              format: "%.2f s")
                    SliderRow(label: "Release",
                              value: $settings.release,
                              range: 0.03...0.3,
                              format: "%.2f s")
                }

                Divider().padding(.vertical, 3)

                // ───── Waveform Picker ─────
                Text("Oscillator Waveform")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Waveform", selection: $settings.amplitudes.waveform) {
                    ForEach(WaveformType.allCases) { waveform in
                        Text(waveform.displayName).tag(waveform)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Divider().padding(.vertical, 3)

                // ───── Harmonic Sliders ─────
                Text("Harmonics & Formant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Group {
                    SliderRow(label: "Fundamental",
                              value: $settings.amplitudes.fundamental, // Direct binding
                              range: 0...1)
                    SliderRow(label: "2nd Harmonic",
                              value: $settings.amplitudes.harmonic2, // Direct binding
                              range: 0...1)
                    SliderRow(label: "3rd Harmonic",
                              value: $settings.amplitudes.harmonic3, // Direct binding
                              range: 0...1)
                    SliderRow(label: "Formant",
                              value: $settings.amplitudes.formant, // Direct binding
                              range: 0...0.3)
                    SliderRow(label: "Formant Freq",
                              value: $settings.amplitudes.formantFrequency, // Direct binding
                              range: 800...1200,
                              format: "%.0f Hz")
                }

                Divider().padding(.vertical, 3)

                // ───── Noise Controls ─────
                Text("Noise Generator")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Noise Type", selection: $settings.amplitudes.noiseType) {
                    ForEach(NoiseType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                SliderRow(label: "Noise Level",
                          value: $settings.amplitudes.noiseLevel, // Bind to noiseLevel
                          range: 0...0.5)

                Divider().padding(.vertical, 3)
                
                // ───── EQ Controls ─────
                Text("Equalizer (Gain)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Group {
                    SliderRow(label: "Low Band", // Changed from Low Shelf for more general EQ
                              value: $settings.amplitudes.eqLowGain,
                              range: -24...24, // Standard gain range for EQs
                              format: "%.1f dB")
                    SliderRow(label: "Mid Band",
                              value: $settings.amplitudes.eqMidGain,
                              range: -24...24,
                              format: "%.1f dB")
                    SliderRow(label: "High Band", // Changed from High Shelf
                              value: $settings.amplitudes.eqHighGain,
                              range: -24...24,
                              format: "%.1f dB")
                }
            }
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                tonePlayer.play(
                    frequency: frequency,
                    duration: duration,
                    amplitudes: settings.amplitudes,
                    attack: settings.attack,
                    release: settings.release
                )
                playing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    playing = false
                }
            }) {
                Label(playing ? "Playing..." : "Play",
                      systemImage: playing ? "waveform" : "play.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        playing
                          ? Color.green.opacity(0.3)
                          : Color.accentColor.opacity(0.17)
                    )
                    .cornerRadius(14)
            }
            .disabled(playing)
            .padding()
            .background(BlurView(style: .systemMaterialDark).ignoresSafeArea())
        }
        .padding(.horizontal)
        .animation(.default, value: settings.amplitudes)
    }
}

fileprivate struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.2f"
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text(String(format: format, value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}

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

struct TonePlayerControlPanel_Previews: PreviewProvider {
    static var previews: some View {
        TonePlayerControlPanel()
            .environmentObject(ToneSettingsManager.shared)
            .frame(width: 370)
            .preferredColorScheme(.dark)
    }
}
