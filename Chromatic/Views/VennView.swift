import SwiftUI

struct VennView: View {
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
    
    /// Check if live pitch is within ±25 cents of fundamental
    private var isAtFundamental: Bool {
        guard let f0 = fundamentalHz else { return false }
        let ratio = tunerData.pitch.measurement.value / f0
        let cents = 1200 * log2(ratio)
        return abs(cents) < 25
    }
    
    private var startOffset: CGFloat {
        CGFloat((1 - percent) * 0.25) // Now a fraction of size, not a fixed px value
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
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let offsetAmount = size * startOffset
            let lineWidth = size * 0.06 + size * 0.12 * tunerData.amplitude
            let waveSize1 = size * 1.1
            let waveSize2 = size * 1.16
            let waveSize3 = size * 1.24
            
            ZStack {
                // 1) Static backdrop ring
                Circle()
                    .stroke(fillColor.opacity(1),
                            lineWidth: lineWidth)
                    .frame(width: size, height: size)
                if isAtFundamental && percent >= 0.8 { WaveCircleBorder(strength: 2, frequency: 30, lineWidth: 3, color: .white, animationDuration: 0.2, autoreverses: false, height: size + 10, width: size + 10)
                } else {
                    WaveCircleBorder(strength: 1, frequency: 60, lineWidth: 1, color: .white, animationDuration: 0.92, autoreverses: false, height: size, width: size)
                }
                
                // 3) Two converging circles
                Group {
                    Circle()
                        .fill(fillColor.opacity(0.5))
                        .frame(width: size, height: size)
                        .scaleEffect(CGFloat(0.8 + 0.2 * percent))
                        .blur(radius: size * 0.05 * (1 - percent))
                        .offset(y: -offsetAmount)
                    
                    Circle()
                        .fill(fillColor.opacity(0.9))
                        .frame(width: size, height: size)
                        .scaleEffect(CGFloat(0.8 + 0.2 * percent))
                        .blur(radius: size * 0.05 * (1 - percent))
                        .offset(y: offsetAmount)
                }
                .blendMode(.darken)
                
                
                // 5) Glowing accents when nearly in tune
                if percent >= 0.8 {
                    
                    
                    Group {
                        Circle()
                            .fill(fillColor.opacity(0.9))
                            .frame(width: size, height: size)
                            .scaleEffect(CGFloat(0.8 + 0.2 * percent))
                            .blur(radius: size * 0.05 * (1 - percent))
                            .offset(y: -offsetAmount)
                        
                        Circle()
                            .fill(fillColor.opacity(0.9))
                            .frame(width: size, height: size)
                            .scaleEffect(CGFloat(0.7 + 0.2 * percent))
                            .blur(radius: size * 0.005 * (1 - percent))
                            .offset(y: offsetAmount)
                    }
                    .blendMode(.saturation)
                }
                
                // Center Label
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
                .font(.system(size: size * 0.17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .offset(y: -size * 0.13)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        
        .aspectRatio(1, contentMode: .fit)
        // Animations outside for overall effect
        .compositingGroup()
        .animation(.interpolatingSpring(stiffness: 80, damping: 20), value: percent)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: tunerData.amplitude)
        .animation(.easeInOut(duration: 0.3), value: tunerData.pitch.measurement.value)
        .animation(.easeInOut(duration: 0.4), value: isAtFundamental)
        
    }
}

struct VennView_Previews: PreviewProvider {
    static var tunerA4 = TunerData(pitch: 200, amplitude: 0.5)
    static var tunerC4 = TunerData(pitch: 261.6, amplitude: 0.8)
    
    static var previews: some View {
        VStack(spacing: 30) {
            Text("In Tune (A4)")
            VennView(distance:   0, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 200)
                .frame(width: 200, height: 200)
            
            Text("Slightly Sharp (+20¢)")
            VennView(distance:  20, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 200)
                .frame(width: 240, height: 240)
            
            Text("Slightly Flat (–9¢)")
            VennView(distance: -12, maxDistance: 50, tunerData: tunerA4, fundamentalHz: 240)
                .frame(width: 180, height: 180)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
