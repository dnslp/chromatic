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
        return Color(hue: Double(idx)/12.0, saturation: 0.8, brightness: 0.9)
    }
    
    // Get all pitch positions for drawing lines
    private var allPitchPositions: [Double] {
        var positions: [Double] = []
        
        if let f0 = f0Percent { positions.append(f0) }
        if let p4 = p4Percent { positions.append(p4) }
        if let p5 = p5Percent { positions.append(p5) }
        if let oct = octavePercent { positions.append(oct) }
        positions.append(contentsOf: harmonicPercents.map(\.percent))
        
        return positions
    }

    var body: some View {
        GeometryReader { geo in
            let markerSize: CGFloat = 12
            let livePitchMarkerSize: CGFloat = 16
            let labelOffsetX: CGFloat = 20
            let lineWidth: CGFloat = 0.5
            
            ZStack(alignment: .top) {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground).opacity(0.2),
                        Color(.systemBackground).opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(8)
                
                // Pitch lines
                ForEach(allPitchPositions, id: \.self) { position in
                    Path { path in
                        let y = (1 - CGFloat(position)) * (geo.size.height - markerSize)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(
                        Color.secondary.opacity(0.15),
                        style: StrokeStyle(lineWidth: lineWidth, dash: [2])
                    )
                }
                
                // Main track with glow effect
                ZStack {
                    Capsule()
                        .frame(width: 6, height: geo.size.height)
                        .foregroundColor(Color.primary.opacity(0.15))
                    
                    Capsule()
                        .frame(width: 4, height: geo.size.height)
                        .foregroundColor(Color.primary.opacity(0.1))
                }
                .shadow(color: .blue.opacity(0.1), radius: 2, y: 1)

                // Harmonic markers & labels (1x-4x of f0)
                ForEach(harmonicPercents, id: \.multiplier) { mult, p in
                    if mult > 1 { // only draw 2x, 3x, 4x distinct from main f0 marker
                        HStack(spacing: 4) {
                            Circle() // Small circle for higher harmonics
                                .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                                .frame(width: markerSize * 0.7, height: markerSize * 0.7)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground).opacity(0.8))
                                )
                            
                            Text("\(mult)×")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.primary.opacity(0.8))
                        }
                        .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.7))
                    }
                }
                
                // Fundamental (f0) marker (outlined blue circle)
                if let p = f0Percent {
                    HStack(spacing: 4) {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: markerSize, height: markerSize)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground).opacity(0.8))
                            )
                        
                        Text("f₀")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.blue)
                    }
                    .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize))
                }

                // Perfect Fourth marker (Green Square)
                if let p = p4Percent {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: markerSize * 0.8, height: markerSize * 0.8)
                            .background(
                                Rectangle()
                                    .fill(Color(.systemBackground).opacity(0.8))
                            )
                        
                        Text("P4")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.green)
                    }
                    .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.8))
                }

                // Perfect Fifth marker (Orange Diamond)
                if let p = p5Percent {
                    HStack(spacing: 4) {
                        Rectangle() // Diamond shape
                            .fill(Color.orange)
                            .frame(width: markerSize * 0.8, height: markerSize * 0.8)
                            .rotationEffect(.degrees(45))
                            .background(
                                Rectangle()
                                    .fill(Color(.systemBackground).opacity(0.8))
                                    .rotationEffect(.degrees(45))
                            )
                        
                        Text("P5")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.orange)
                    }
                    .offset(x: labelOffsetX + 2, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.8))
                }
                
                // Octave marker (Purple Circle, thicker stroke)
                if let p = octavePercent {
                     HStack(spacing: 4) {
                        Circle()
                            .stroke(Color.purple, lineWidth: 2.5)
                            .frame(width: markerSize * 0.9, height: markerSize * 0.9)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground).opacity(0.8))
                            )
                        
                        Text("Oct")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.purple)
                    }
                    .offset(x: labelOffsetX, y: (1 - CGFloat(p)) * (geo.size.height - markerSize * 0.9))
                }

                // Live-pitch marker (filled circle with glow)
                ZStack {
                    Circle()
                        .fill(fillColor)
                        .frame(width: livePitchMarkerSize, height: livePitchMarkerSize)
                        .shadow(color: fillColor, radius: 6, x: 0, y: 0)
                    
                    Circle()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                        .frame(width: livePitchMarkerSize + 6, height: livePitchMarkerSize + 6)
                }
                .offset(y: (1 - CGFloat(livePitchPercent)) * (geo.size.height - livePitchMarkerSize))
                .animation(.spring(response: 0.15, dampingFraction: 0.5), value: livePitchPercent)
                
                // Frequency scale
                VStack(alignment: .leading) {
                    Text("\(Int(maxHz))Hz")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(minHz))Hz")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 4)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 70)
        .padding(.vertical, 8)
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
                .font(.headline)
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 100),
                frequency: Frequency(floatLiteral: 100),
                profile: sampleProfile1
            )
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)

            Text("Live: 300Hz, Profile: 150Hz (f0)")
                .font(.headline)
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 300),
                frequency: Frequency(floatLiteral: 300),
                profile: sampleProfile2
            )
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)

            Text("Live: 80Hz, Profile: 200Hz (f0)")
                .font(.headline)
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 80),
                frequency: Frequency(floatLiteral: 80),
                profile: sampleProfile3
            )
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
            
            Text("Live: 120Hz, No Profile")
                .font(.headline)
            PitchLineVisualizer(
                tunerData: TunerData(pitch: 120),
                frequency: Frequency(floatLiteral: 120),
                profile: noProfile
            )
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
