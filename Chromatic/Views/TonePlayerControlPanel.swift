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
    VowelPreset(name: "A (as in 'father')", amplitudes: .init(fundamental: 0.85, harmonic2: 0.16, harmonic3: 0.08, formant: 0.18, noise: 0.00, formantFrequency: 900)),
    VowelPreset(name: "E (as in 'bed')",    amplitudes: .init(fundamental: 0.75, harmonic2: 0.15, harmonic3: 0.06, formant: 0.11, noise: 0.01, formantFrequency: 1100)),
    VowelPreset(name: "I (as in 'machine')",amplitudes: .init(fundamental: 0.67, harmonic2: 0.19, harmonic3: 0.13, formant: 0.09, noise: 0.01, formantFrequency: 1200)),
    VowelPreset(name: "O (as in 'law')",    amplitudes: .init(fundamental: 0.77, harmonic2: 0.18, harmonic3: 0.09, formant: 0.12, noise: 0.00, formantFrequency: 800)),
    VowelPreset(name: "U (as in 'goose')",  amplitudes: .init(fundamental: 0.83, harmonic2: 0.13, harmonic3: 0.09, formant: 0.07, noise: 0.00, formantFrequency: 850)),
    VowelPreset(name: "Breathy",            amplitudes: .init(fundamental: 0.55, harmonic2: 0.09, harmonic3: 0.03, formant: 0.04, noise: 0.13, formantFrequency: 900)),
    VowelPreset(name: "Whisper",            amplitudes: .init(fundamental: 0.10, harmonic2: 0.01, harmonic3: 0.01, formant: 0.02, noise: 0.49, formantFrequency: 1200))
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

                // ───── Harmonic/Noise Sliders ─────
                Group {
                    SliderRow(label: "Fundamental",
                              value: Binding(
                                  get: { settings.amplitudes.fundamental },
                                  set: { settings.amplitudes.fundamental = $0 }
                              ),
                              range: 0...1)
                    SliderRow(label: "2nd Harmonic",
                              value: Binding(
                                  get: { settings.amplitudes.harmonic2 },
                                  set: { settings.amplitudes.harmonic2 = $0 }
                              ),
                              range: 0...1)
                    SliderRow(label: "3rd Harmonic",
                              value: Binding(
                                  get: { settings.amplitudes.harmonic3 },
                                  set: { settings.amplitudes.harmonic3 = $0 }
                              ),
                              range: 0...1)
                    SliderRow(label: "Formant",
                              value: Binding(
                                  get: { settings.amplitudes.formant },
                                  set: { settings.amplitudes.formant = $0 }
                              ),
                              range: 0...0.3)
                    SliderRow(label: "Formant Freq",
                              value: Binding(
                                  get: { settings.amplitudes.formantFrequency },
                                  set: { settings.amplitudes.formantFrequency = $0 }
                              ),
                              range: 800...1200,
                              format: "%.0f Hz")
                    SliderRow(label: "Noise",
                              value: Binding(
                                  get: { settings.amplitudes.noise },
                                  set: { settings.amplitudes.noise = $0 }
                              ),
                              range: 0...0.5)
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
