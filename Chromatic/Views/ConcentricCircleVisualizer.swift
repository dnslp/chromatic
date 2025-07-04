import SwiftUI
import Foundation

/// Visualizer showing concentric circles filling based on pitch accuracy,
/// with the fill color determined by the note name (C to B) as a hue gradient from red through violet.
struct ConcentricCircleVisualizer: View {
    let distance: Double        // Pitch deviation in cents
    let maxDistance: Double     // Max cents for full scale
    let tunerData: TunerData    // For dynamic styling (pitch & amplitude)

    /// How “full” the circle should be (0…1) based on cent-distance
    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }

    /// Fundamental frequency in Hz
    private var f0Hz: Double {
        tunerData.pitch.measurement.value
    }

    /// MIDI note number estimate for f₀
    private var midiNote: Double {
        69 + 12 * log2(f0Hz / 440)
    }

    /// Semitone index from C (0 = C, 1 = C♯/D♭, ..., 11 = B)
    private var semitoneIndex: Int {
        let rounded = Int(round(midiNote))
        return (rounded % 12 + 12) % 12
    }

    /// Assign hue from 0 to 1 across 12 semitones: C=0 (red), B≈11/12 (violet)
    private var fillColor: Color {
        Color(hue: Double(semitoneIndex) / 12.0, saturation: 1, brightness: 1)
    }

    var body: some View {
        ZStack {
            // Outer ring indicates amplitude
            Circle()
                .stroke(lineWidth: 20 * tunerData.amplitude)
                .foregroundColor(.secondary)
                .frame(width: 100, height: 100)

            // Inner fill uses note-based hue
            Circle()
                .frame(width: 100, height: 100)
                .scaleEffect(CGFloat(percent))
                .foregroundColor(fillColor.opacity(0.6))
                .animation(.easeInOut(duration: 0.5), value: percent)
        }
    }
}

// MARK: - Preview
struct ConcentricCircleVisualizer_Previews: PreviewProvider {
    static var tunerA4 = TunerData(pitch: 440, amplitude: 0.5)
    static var tunerC4 = TunerData(pitch: 261.6, amplitude: 0.8)

    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                Text("A4 (440 Hz) → A note hue")
                ConcentricCircleVisualizer(
                    distance: 0,
                    maxDistance: 50,
                    tunerData: tunerA4
                )
                Text("C4 (261.6 Hz) → C note hue")
                ConcentricCircleVisualizer(
                    distance: 20,
                    maxDistance: 50,
                    tunerData: tunerC4
                )
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
}
