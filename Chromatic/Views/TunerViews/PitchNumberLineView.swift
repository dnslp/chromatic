import SwiftUI

/// Label mode: either show semitone offsets or pitch names
enum PitchLabelMode {
    case numeric   // e.g. -7, -5, ...
    case noteNames // e.g. C4, D#4, etc.
}

/// A horizontal number line from –7 to +12 semitone steps around userF0,
/// with tick marks and an optional moving marker for liveF0.
struct PitchNumberLineView: View {
    let userF0: Double
    let liveF0: Double
    var labelMode: PitchLabelMode = .numeric
    
    // steps below (–7) up to +12 semitones
    private let minStep = -7
    private let maxStep = 12
    
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    var body: some View {
        GeometryReader { geo in
            let totalSteps = Double(maxStep - minStep)
            let width = geo.size.width
            
            // draw tick marks + labels
            ForEach(minStep...maxStep, id: \.self) { step in
                let isRoot = (step == 0)
                let xPos = CGFloat(Double(step - minStep) / totalSteps) * width
                
                // vertical tick line
                Path { path in
                    let h: CGFloat = isRoot ? 20 : 12
                    path.move(to: CGPoint(x: xPos, y: 0))
                    path.addLine(to: CGPoint(x: xPos, y: h))
                }
                .stroke(isRoot ? Color.accentColor : Color.secondary,
                        lineWidth: isRoot ? 2 : 1)
                
                // label
                if step % 1 == 0 {
                    let labelText: String = {
                        switch labelMode {
                        case .numeric:
                            return "\(step)"
                        case .noteNames:
                            return pitchName(for: step)
                        }
                    }()
                    
                    Text(labelText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(x: xPos, y: 30)
                }
            }
            
            // draw live-pitch marker
            let centsDiff = 1200 * log2(liveF0 / userF0)
            let semitoneDiff = centsDiff / 100
            let clamped = min(Double(maxStep), max(Double(minStep), semitoneDiff))
            let markerX = CGFloat((clamped - Double(minStep)) / totalSteps) * width
            
            Circle()
                .fill(Color.red)
                .frame(width: 20, height: 20).opacity(0.5)
                .position(x: markerX, y: geo.size.height * 0.5 + 10)
                .shadow(radius: 2)
        }
        .frame(height: 40)
        .padding(.horizontal)
    }
    
    /// Compute an approximate pitch name for a given semitone offset from userF0
    private func pitchName(for step: Int) -> String {
        guard userF0 > 0 else { return "–" }
        // convert userF0 to nearest MIDI note
        let midi = Int(round(12 * log2(userF0 / 440) + 69))
        let noteIndex = (midi + step) % 12 < 0 ? (midi + step + 12) % 12 : (midi + step) % 12
        let octave = (midi + step) / 12 - 1
        return "\(noteNames[noteIndex])\(octave)"
    }
}

struct PitchNumberLineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            Text("Numeric mode:")
            PitchNumberLineView(userF0: 261.63, liveF0: 275.0, labelMode: .numeric)
            Text("Note-name mode:")
            PitchNumberLineView(userF0: 261.63, liveF0: 275.0, labelMode: .noteNames)
        }
        .padding()
    }
}
