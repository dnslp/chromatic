//
//  TuningOverlapCirclesView.swift
//  Chromatic
//
//  Created by David Nyman on 7/10/25.
//
import SwiftUI

struct TuningOverlapCirclesView: View {
    var targetF0: Double
    var liveF0: Double

    let maxOffset: CGFloat = 54
    let inTuneThresholdCents: Double = 24.0 // forgiving

    @State private var animOffsetY: CGFloat = 0
    @State private var animIsInTune: Bool = false
    @State private var animColor: Color = .green

    // Calculate cents difference and direction
    var centsDiff: Double {
        guard targetF0 > 0 && liveF0 > 0 else { return 0 }
        return 1200 * log2(liveF0 / targetF0)
    }
    var offsetY: CGFloat {
        let capped = max(min(centsDiff, 50), -50)
        return -CGFloat(capped / 50) * maxOffset
    }
    var isInTune: Bool {
        abs(centsDiff) <= inTuneThresholdCents
    }
    var liveCircleColor: Color {
        isInTune ? .green : (centsDiff < 0 ? .blue : .yellow)
    }
    
    func noteNameAndCents(for frequency: Double) -> (String, Int) {
        guard frequency > 0 else { return ("–", 0) }
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let freqRatio = frequency / 440.0
        let midiDouble = 69.0 + 12.0 * log2(freqRatio)
        let midi = Int(round(midiDouble))
        let noteIndex = (midi + 120) % 12
        let noteName = noteNames[noteIndex]
        let noteHz = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
        let centsDouble = 1200.0 * log2(frequency / noteHz)
        let cents = Int(round(centsDouble))
        let octave = (midi / 12) - 1
        return ("\(noteName)\(octave)", cents)
    }


    var body: some View {
        ZStack {
            // Target Circle (centered)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(animIsInTune ? 0.23 : 0.10),
                            Color.clear
                        ]),
                        center: .center, startRadius: 0, endRadius: 42
                    )
                )
                .frame(width: 88, height: 88)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(animIsInTune ? 0.46 : 0.19), lineWidth: animIsInTune ? 8 : 3)
                        .blur(radius: animIsInTune ? 3 : 0)
                        .animation(.easeInOut(duration: 0.4), value: animIsInTune)
                )
            

            // Live Pitch Circle (animated offset and color)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            animColor,
                            Color.clear
                        ]),
                        center: .center, startRadius: 0, endRadius: 42
                    )
                )
                .frame(width: 88, height: 88)
                .offset(y: animOffsetY)
                .overlay(
                    Circle()
                        .stroke(animColor, lineWidth: animIsInTune ? 7 : 3)
                        .blur(radius: animIsInTune ? 3 : 0)
                        .shadow(color: animColor.opacity(0.28), radius: 8)
                        .animation(.interpolatingSpring(stiffness: 170, damping: 20), value: animIsInTune)
                )
                .animation(.interpolatingSpring(stiffness: 170, damping: 19), value: animOffsetY)

            // Checkmark
            if animIsInTune {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 30, weight: .bold))
                    .opacity(0.9)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 220, height: 90)
        .padding(.vertical, 8)
        let (note, cents) = noteNameAndCents(for: liveF0)
        VStack(spacing: 2) {
            Text("\(note)")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Text(cents == 0 ? "in tune" : String(format: "%+d cents", cents))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(cents == 0 ? .green : .secondary)
        }
        .padding(.top, 8)
        .onChange(of: offsetY) { newOffset in
            withAnimation(.interpolatingSpring(stiffness: 140, damping: 16)) {
                animOffsetY = newOffset
            }
        }
        .onChange(of: isInTune) { newValue in
            withAnimation(.easeInOut(duration: 0.23)) {
                animIsInTune = newValue
            }
        }
        .onChange(of: liveCircleColor) { newColor in
            withAnimation(.easeInOut(duration: 0.18)) {
                animColor = newColor
            }
        }
        .onAppear {
            animOffsetY = offsetY
            animIsInTune = isInTune
            animColor = liveCircleColor
        }
    }
}

struct TuningOverlapCirclesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Text("Perfectly in Tune").bold()
                TuningOverlapCirclesView(targetF0: 220, liveF0: 220)
            }
            .previewDisplayName("In Tune")
            VStack {
                Text("Slightly Sharp (above)").bold()
                TuningOverlapCirclesView(targetF0: 220, liveF0: 221.5)
            }
            .previewDisplayName("Slightly Sharp")
            VStack {
                Text("Slightly Flat (below)").bold()
                TuningOverlapCirclesView(targetF0: 220, liveF0: 218.5)
            }
            .previewDisplayName("Slightly Flat")
            VStack {
                Text("Very Sharp").bold()
                TuningOverlapCirclesView(targetF0: 220, liveF0: 240)
            }
            .previewDisplayName("Very Sharp")
            VStack {
                Text("Very Flat").bold()
                TuningOverlapCirclesView(targetF0: 220, liveF0: 200)
            }
            .previewDisplayName("Very Flat")
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
