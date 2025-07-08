// // TonePlayerControlPanel.swift // Chromatic // // Created by David Nyman on 7/8/25. //

import SwiftUI

struct VowelPreset: Identifiable { let id = UUID() let name: String let amplitudes: HarmonicAmplitudes }

let vowelPresets: [VowelPreset] = [ VowelPreset(name: "A (as in 'father')", amplitudes: HarmonicAmplitudes(fundamental: 0.85, harmonic2: 0.16, harmonic3: 0.08, formant: 0.18, noise: 0.00, formantFrequency: 900)), VowelPreset(name: "E (as in 'bed')", amplitudes: HarmonicAmplitudes(fundamental: 0.75, harmonic2: 0.15, harmonic3: 0.06, formant: 0.11, noise: 0.01, formantFrequency: 1100)), VowelPreset(name: "I (as in 'machine')",amplitudes: HarmonicAmplitudes(fundamental: 0.67, harmonic2: 0.19, harmonic3: 0.13, formant: 0.09, noise: 0.01, formantFrequency: 1200)), VowelPreset(name: "O (as in 'law')", amplitudes: HarmonicAmplitudes(fundamental: 0.77, harmonic2: 0.18, harmonic3: 0.09, formant: 0.12, noise: 0.00, formantFrequency: 800)), VowelPreset(name: "U (as in 'goose')", amplitudes: HarmonicAmplitudes(fundamental: 0.83, harmonic2: 0.13, harmonic3: 0.09, formant: 0.07, noise: 0.00, formantFrequency: 850)), VowelPreset(name: "Breathy", amplitudes: HarmonicAmplitudes(fundamental: 0.55, harmonic2: 0.09, harmonic3: 0.03, formant: 0.04, noise: 0.13, formantFrequency: 900)), VowelPreset(name: "Whisper", amplitudes: HarmonicAmplitudes(fundamental: 0.1, harmonic2: 0.01, harmonic3: 0.01, formant: 0.02, noise: 0.49, formantFrequency: 1200)) ]

struct TonePlayerControlPanel: View {
    @EnvironmentObject var toneSettings: ToneSettingsManager // Use shared settings

    @State private var frequency: Double = 220
    @State private var duration: Double = 1.2
    @State private var attack: Double = 0.04
    @State private var release: Double = 0.12
    // Removed: @State private var harmonicAmplitudes = HarmonicAmplitudes()
    // Removed: @StateObject private var tonePlayer = TonePlayer()
    @State private var playing = false
    @State private var selectedPreset: VowelPreset? = nil

    // Local player for the play button in this panel
    private var localTonePlayer = TonePlayer()

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
                                self.toneSettings.harmonicAmplitudes = preset.amplitudes
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
                    SliderRow(label: "Fundamental", value: $toneSettings.harmonicAmplitudes.fundamental, range: 0...1)
                    SliderRow(label: "2nd Harmonic", value: $toneSettings.harmonicAmplitudes.harmonic2, range: 0...1)
                    SliderRow(label: "3rd Harmonic", value: $toneSettings.harmonicAmplitudes.harmonic3, range: 0...1)
                    SliderRow(label: "Formant", value: $toneSettings.harmonicAmplitudes.formant, range: 0...0.3)
                    SliderRow(
                        label: "Formant Freq",
                        value: $toneSettings.harmonicAmplitudes.formantFrequency,
                        range: 800...1200,
                        format: "%.0f Hz"
                    )
                    SliderRow(label: "Noise", value: $toneSettings.harmonicAmplitudes.noise, range: 0...0.5)
                }
            }
            .padding(.bottom, 16) // So Play button doesn't overlap with the scroll end
        }
        // Play button always visible at the bottom
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                localTonePlayer.play( // Use localTonePlayer instance
                    frequency: frequency,
                    duration: duration,
                    amplitudes: toneSettings.harmonicAmplitudes, // Use shared amplitudes
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
        .animation(.default, value: toneSettings.harmonicAmplitudes) // Animate based on shared settings
    }
}

// --- Helper Slider Row ---
// Note: The original code had an issue here. The `range` and `format` parameters in the struct
// did not match the initializer call (e.g., `SliderRow(label: "Frequency", value: $frequency, range: 80...880, format: "%.1f Hz")`)
// I will assume a corrected SliderRow that can handle this.
// For the purpose of this step, I will use the SliderRow as provided, but it might need fixing.
// Let's define a SliderRow that matches its usage.
fileprivate struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String? // Make format optional or provide a default in init

    // Initializer to match usage
    init(label: String, value: Binding<Double>, range: ClosedRange<Double>, format: String? = "%.2f") {
        self.label = label
        self._value = value
        self.range = range
        self.format = format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                if let fmt = format {
                    Text(String(format: fmt, value))
                        .font(.caption.monospacedDigit())
                } else {
                    // Default formatting if not provided, or handle as error
                    Text(String(format: "%.2f", value))
                        .font(.caption.monospacedDigit())
                }
            }
            Slider(value: $value, in: range)
        }
    }
}


// --- Optional: Blur background for bottom sheet --- #if canImport(UIKit)
import UIKit
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#else
struct BlurView: View {
    var style: Any // Placeholder for non-UIKit platforms
    var body: some View { Color.clear }
}
#endif

// MARK: - Preview
struct TonePlayerControlPanel_Previews: PreviewProvider {
    static var previews: some View {
        TonePlayerControlPanel()
            .environmentObject(ToneSettingsManager.shared) // Add shared settings for preview
            .frame(width: 370)
            .preferredColorScheme(.dark)
    }
}

// Placeholder for HarmonicAmplitudes and TonePlayer if not defined globally
// These should ideally be in their own files or a shared model file.
// For compilation, I'll add basic stubs here.
// Ensure these match your actual definitions.
struct HarmonicAmplitudes: Equatable {
    var fundamental: Double = 0.75
    var harmonic2: Double = 0.1
    var harmonic3: Double = 0.05
    var formant: Double = 0.1
    var noise: Double = 0.01
    var formantFrequency: Double = 1000

    // Default initializer
    init(fundamental: Double = 0.75, harmonic2: Double = 0.1, harmonic3: Double = 0.05, formant: Double = 0.1, noise: Double = 0.01, formantFrequency: Double = 1000) {
        self.fundamental = fundamental
        self.harmonic2 = harmonic2
        self.harmonic3 = harmonic3
        self.formant = formant
        self.noise = noise
        self.formantFrequency = formantFrequency
    }
}

class TonePlayer: ObservableObject {
    func play(frequency: Double, duration: Double, amplitudes: HarmonicAmplitudes, attack: Double, release: Double) {
        // Dummy implementation
        print("Playing tone: freq \(frequency), dur \(duration), amps \(amplitudes), att \(attack), rel \(release)")
    }
    func stop() {
        // Dummy implementation
        print("Tone stopped")
    }
     func play(frequency: Double, duration: Double) {
        // Dummy implementation for simpler calls
        print("Playing simple tone: freq \(frequency), dur \(duration)")
    }
}
