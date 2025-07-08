import SwiftUI

/// Visualizer showing:
///  - the current input pitch (filled circle, colored by note)
///  - markers for f0, P4, P5, Octave from the UserProfile
///  - the first four harmonics of f0 (small stroked circles + labels)
/// on a vertical track from `minHz`–`maxHz`.
struct PitchLineVisualizer: View {
    let tunerData: TunerData
    let frequency: Frequency // Live pitch
    let profile: UserProfile? // User's selected profile
    
    let minHz: Double = 55 // A1
    let maxHz: Double = 987.77 // B5, approx C6 - B2. Adjusted for wider range if needed.

    // Helper to calculate normalized percentage for a given frequency
    private func normalize(_ hzValue: Double) -> Double? {
        let p = (hzValue - minHz) / (maxHz - minHz)
        return (0...1).contains(p) ? p : nil
    }

    /// normalized 0–1 for the live pitch
    private var livePitchPercent: Double {
        normalize(frequency.measurement.value) ?? 0 // Default to 0 if out of range
    }

    /// normalized 0–1 for f₀ from profile
    private var f0Percent: Double? {
        guard let f0 = profile?.f0 else { return nil }
        return normalize(f0)
    }
    
    /// normalized 0–1 for Perfect Fourth from profile
    private var p4Percent: Double? {
        guard let p4 = profile?.perfectFourth else { return nil }
        return normalize(p4)
    }
    
    /// normalized 0–1 for Perfect Fifth from profile
    private var p5Percent: Double? {
        guard let p5 = profile?.perfectFifth else { return nil }
        return normalize(p5)
    }
    
    /// normalized 0–1 for Octave from profile
    private var octavePercent: Double? {
        guard let oct = profile?.octave else { return nil }
        return normalize(oct)
    }

    /// normalized positions for harmonics 1×…4× of f0 from profile
    private var harmonicPercents: [(multiplier: Int, percent: Double)] {
        guard let f0 = profile?.f0 else { return [] }
        return (1...4).compactMap { i -> (Int, Double)? in
            let harmonicFrequency = f0 * Double(i)
            if let p = normalize(harmonicFrequency) {
                return (i, p)
            }
            return nil
        }
    }

    private var fillColor: Color {
        let hz   = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx  = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(idx)/12.0, saturation: 1, brightness: 1)
    }

    var body: some View {
        GeometryReader { geo in
            let markerSize: CGFloat = 12
            let livePitchMarkerSize: CGFloat = 16
            let labelOffsetX: CGFloat = 18 // Increased to avoid overlap with markers

            ZStack(alignment: .top) {
                // 1) Full-height track
                Capsule()
                    .frame(width: 4, height: geo.size.height)
                    .foregroundColor(Color.gray.opacity(0.3))

                // 2) Harmonic markers & labels (1x-4x of f0)
                ForEach(harmonicPercents, id: \.multiplier) { mult, p in
                    if mult > 1 { // only draw 2x, 3x, 4x distinct from main f0 marker
                        HStack(spacing: 4) {
                            Circle() // Small circle for higher harmonics
                                .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                                .frame(width: markerSize * 0.7, height: markerSize * 0.7)
                            Text("\(mult)x")
                                .font(.caption2)
                                .foregroundColor(Color.primary.opacity(0.7))
                        }
                        .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.7))
                    }
                }
                
                // 3) Fundamental (f0) marker (outlined blue circle)
                if let p = f0Percent {
                    HStack(spacing: 4) {
                        Circle()
                            .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                            .frame(width: markerSize, height: markerSize)
                        Text("f₀")
                            .font(.caption2.bold())
                            .foregroundColor(Color.blue.opacity(0.9))
                    }
                    .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize))
                }

                // Perfect Fourth marker (Green Square)
                if let p = p4Percent {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: markerSize * 0.8, height: markerSize * 0.8)
                        Text("P4")
                            .font(.caption2)
                            .foregroundColor(Color.green.opacity(0.9))
                    }
                    .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.8))
                }

                // Perfect Fifth marker (Orange Diamond)
                if let p = p5Percent {
                    HStack(spacing: 4) {
                        Rectangle() // Diamond shape
                            .fill(Color.orange.opacity(0.8))
                            .frame(width: markerSize * 0.8, height: markerSize * 0.8)
                            .rotationEffect(.degrees(45))
                        Text("P5")
                            .font(.caption2)
                            .foregroundColor(Color.orange.opacity(0.9))
                    }
                     .offset(x: labelOffsetX + 2, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.8)) // +2 to x to center diamond better
                }
                
                // Octave marker (Purple Circle, thicker stroke)
                if let p = octavePercent {
                     HStack(spacing: 4) {
                        Circle()
                            .stroke(Color.purple.opacity(0.8), lineWidth: 2.5)
                            .frame(width: markerSize * 0.9, height: markerSize * 0.9)
                        Text("Oct")
                            .font(.caption2)
                            .foregroundColor(Color.purple.opacity(0.9))
                    }
                    .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.9))
                }

                // Live-pitch marker (filled circle)
                Circle()
                    .frame(width: livePitchMarkerSize, height: livePitchMarkerSize)
                    .foregroundColor(fillColor)
                    .offset(y: (1 - CGFloat(livePitchPercent)) * (geo.size.height - livePitchMarkerSize))
                    .animation(.easeInOut(duration: 0.1), value: livePitchPercent) // Faster animation
            }
        }
        .frame(width: 65) // Widen a bit more for new labels
    }
}


struct PitchLineVisualizer_Previews: PreviewProvider {
    static let sampleProfile1 = UserProfile(name: "Profile 100Hz", f0: 100.0)
    static let sampleProfile2 = UserProfile(name: "Profile 150Hz", f0: 150.0)
    static let sampleProfile3 = UserProfile(name: "Profile 200Hz", f0: 200.0)
    static let noProfile: UserProfile? = nil

    static var previews: some View {
        VStack(spacing: 40) {
            Text("Live: 100Hz, Profile: 100Hz (f0)")
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 100),
                frequency: Frequency(floatLiteral: 100),
                profile: sampleProfile1
            )
            .frame(height: 250) // Increased height for better visualization

            Text("Live: 300Hz, Profile: 150Hz (f0)")
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 300),
                frequency: Frequency(floatLiteral: 300),
                profile: sampleProfile2
            )
            .frame(height: 250)

            Text("Live: 80Hz, Profile: 200Hz (f0)")
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 80),
                frequency: Frequency(floatLiteral: 80),
                profile: sampleProfile3
            )
            .frame(height: 250)
            
            Text("Live: 120Hz, No Profile")
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 120),
                frequency: Frequency(floatLiteral: 120),
                profile: noProfile
            )
            .frame(height: 250)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
