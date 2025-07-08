import SwiftUI

struct ConcentricCircleVisualizer: View {
    let distance: Double
    let maxDistance: Double
    let tunerData: TunerData
    let fundamentalHz: Double?  // optional user-defined fundamental frequency in Hz
    
    
    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }
    
    private var f0: Double { fundamentalHz ?? tunerData.pitch.measurement.value }
    private var freqDifference: Double { tunerData.pitch.measurement.value - f0 }
    private var centsDifference: Double {
        guard tunerData.pitch.measurement.value > 0, f0 > 0 else { return 0 }
        return 1200 * log2(tunerData.pitch.measurement.value / f0)
    }
    
    private var fillColor: Color {
        let hz   = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx  = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(idx)/12.0, saturation: 1, brightness: 1)
    }
    
    /// Check if live pitch is within ±5 cents of fundamental
    private var isAtFundamental: Bool {
        guard let f0 = fundamentalHz else { return false }
        let ratio = tunerData.pitch.measurement.value / f0
        let cents = 1200 * log2(ratio)
        return abs(cents) < 25
    }
    
    private var startOffset: CGFloat {
        CGFloat((1 - percent) * 30)
    }
    
    enum PitchMatchLabel: String {
        case fundamental = "f₀"
        case perfectFourth = "P4"
        case perfectFifth = "P5"
        case harmonic1 = "f₁"
        case harmonic2 = "f₂"
        case harmonic3 = "f₃"
        case harmonic4 = "f₄"
        case none
    }

    func pitchMatchLabel(pitchHz: Double, f0: Double, toleranceCents: Double = 20) -> PitchMatchLabel {
        guard pitchHz > 0, f0 > 0 else { return .none }
        let centsDiff: (Double, Double) -> Double = { a, b in 1200 * log2(a / b) }
        if abs(centsDiff(pitchHz, f0)) < toleranceCents { return .fundamental }
        else if abs(centsDiff(pitchHz, f0 * 4 / 3)) < toleranceCents { return .perfectFourth }
        else if abs(centsDiff(pitchHz, f0 * 3 / 2)) < toleranceCents { return .perfectFifth }
        else if abs(centsDiff(pitchHz, f0 * 2)) < toleranceCents { return .harmonic1 }
        else if abs(centsDiff(pitchHz, f0 * 3)) < toleranceCents { return .harmonic2 }
        else if abs(centsDiff(pitchHz, f0 * 4)) < toleranceCents { return .harmonic3 }
        else if abs(centsDiff(pitchHz, f0 * 5)) < toleranceCents { return .harmonic4 }
        return .none
    }
    
    var body: some View {
        ZStack {
   

            // 1) Static backdrop ring
            Circle()
                .stroke(Color.secondary.opacity(0.2),
                        lineWidth: CGFloat(4 + 8 * tunerData.amplitude))
                .frame(width: 100, height: 100)
            
            // 2) Waving circle for amplitude (background)
            WavingCircleBorder(
                strength: tunerData.amplitude * 5,
                frequency: 10, // Lowered frequency for a gentler pulse
                lineWidth: 2,
                color: fillColor.opacity(0.1 + 0.2 * tunerData.amplitude),
                animationDuration: 1.5, // Slower wave cycle
                autoreverses: true
            )
            .frame(width: 110, height: 110)
            
            // 3) Two converging circles
            Group {
                Circle()
                    .fill(fillColor.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .scaleEffect(CGFloat(0.8 + 0.2 * percent))
                    .blur(radius: CGFloat(5 * (1 - percent)))
                    .offset(x: -startOffset)
                
                Circle()
                    .fill(fillColor.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .scaleEffect(CGFloat(0.8 + 0.2 * percent))
                    .blur(radius: CGFloat(5 * (1 - percent)))
                    .offset(x: startOffset)
            }
            .blendMode(.plusLighter)
            
            // 4) Waving borders (main)
            WavingCircleBorder(
                strength: 4,
                frequency: tunerData.pitch.measurement.value,
                lineWidth: 0.5 - percent, // Gets thinner when in tune
                color: fillColor.opacity(0.3),
                animationDuration: 0.8, // Slower wave cycle
                autoreverses: false
            )
            .frame(width: 116, height: 116)
            
            WavingCircleBorder(
                strength: 9,
                frequency: tunerData.pitch.measurement.value,
                lineWidth: 1 - percent, // Gets thinner when in tune
                color: fillColor.opacity(0.3),
                animationDuration: 0.6, // Slower wave cycle
                autoreverses: false
            )
            .frame(width: 124, height: 124)
            
            // 5) Glowing accents when nearly in tune
            if percent >= 0.8 {
                WavingCircleBorder(
                    strength: 1,
                    frequency: tunerData.pitch.measurement.value / 100,
                    lineWidth: isAtFundamental ? 1 : 3,
                    color: isAtFundamental ? .white : fillColor.opacity(0.9),
                    animationDuration: 1,
                    autoreverses: false
                )
                .frame(width: 130, height: 130)
                
                WavingCircleBorder(
                    strength: 1,
                    frequency: 1,
                    lineWidth: isAtFundamental ? 18 : 3,
                    color: isAtFundamental ? .white : fillColor.opacity(0.9),
                    animationDuration: 0.9,
                    autoreverses: false
                )
                .frame(width: 140, height: 140)
            }
        }
        .compositingGroup()
        // Apply animations to the ZStack for better coordination
        .animation(.interpolatingSpring(stiffness: 80, damping: 20), value: percent) // Softer spring
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: tunerData.amplitude) // Gentler spring
        .animation(.easeInOut(duration: 0.3), value: tunerData.pitch.measurement.value) // Smooth pitch changes
        .animation(.easeInOut(duration: 0.4), value: isAtFundamental)

        let match = pitchMatchLabel(
            pitchHz: tunerData.pitch.measurement.value,
            f0: fundamentalHz ?? tunerData.pitch.measurement.value
        )
        let freqDifference = tunerData.pitch.measurement.value - (fundamentalHz ?? tunerData.pitch.measurement.value)

        Text(
            match != .none ?
                match.rawValue :
                "\(String(format: "%.2f", freqDifference)) Hz"
        )
        .font(.headline)
        .bold()
        .offset(y: -20)
        // Individual animations for text if needed, but often benefits from container's animation
        // For instance, if text content changes and needs its own transition:
        // .animation(.easeInOut(duration: 0.2), value: match.rawValue)
        // .animation(.easeInOut(duration: 0.2), value: freqDifference)
        
    }
}
struct ConcentricCircleVisualizer_Previews: PreviewProvider {
    static var tunerA4 = TunerData(pitch: 200, amplitude: 0.5)
    static var tunerC4 = TunerData(pitch: 261.6, amplitude: 0.8)

    static var previews: some View {
        VStack(spacing: 30) {
            Text("In Tune (A4)")
            ConcentricCircleVisualizer(distance:   0, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 200)

            Text("Slightly Sharp (+20¢)")
            ConcentricCircleVisualizer(distance:  20, maxDistance: 0, tunerData: tunerA4, fundamentalHz: 100)

            Text("Slightly Flat (–9¢)")
            ConcentricCircleVisualizer(distance: -9, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 431)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
