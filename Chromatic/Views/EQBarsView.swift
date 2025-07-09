import SwiftUI

/// Simple bar-style visualizer used by the tuner to show the incoming
/// signal strength. Each bar grows with the microphone amplitude and
/// changes color based on how far off pitch the detected note is.

struct EQBarsView: View {
    let match: ScaleNote.Match
    let tunerData: TunerData
    let eqBarCount: Int
    let eqMaxHeight: CGFloat

    var body: some View {
        // Bars are arranged horizontally and aligned to the bottom so
        // varying heights appear to rise from a common baseline.
        HStack(alignment: .bottom, spacing: 22) {
            ForEach(0..<eqBarCount, id: \.self) { i in
                // Pick color based on how close the measured pitch is to the target.
                // ±5 cents is green, ±25 cents is yellow, otherwise red.
                let d = abs(match.distance.cents)
                let c: Color = d < 5 ? .green : (d < 25 ? .yellow : .red)

                // Bars in the center are tallest while outer bars taper off.
                // This creates a simple EQ style shape that scales with amplitude.
                let center = Double(eqBarCount - 1) / 2
                let factor = 1.5 - abs(Double(i) - center) / center
                let height = eqMaxHeight * CGFloat(tunerData.amplitude) * CGFloat(factor)
                Capsule()
                    .frame(width: 8, height: height)
                    .foregroundColor(c)
                    .animation(.easeInOut(duration: 0.2), value: tunerData.amplitude)
            }
        }
        // Expand to the provided maximum height and horizontally fill the
        // available space while leaving room for surrounding UI.
        .frame(height: eqMaxHeight)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 25)
        .padding(.bottom, 35)
    }
}

struct EQBarsView_Previews: PreviewProvider {
    static var previews: some View {
        let match1 = ScaleNote.Match(note: .A, octave: 4, distance: 0)
        let tunerData1 = TunerData(pitch: 440.0, amplitude: 0.8)

        let match2 = ScaleNote.Match(note: .C, octave: 3, distance: Frequency.MusicalDistance(cents: 30))
        let tunerData2 = TunerData(pitch: 135.0, amplitude: 0.5)

        let match3 = ScaleNote.Match(note: .GSharp_AFlat, octave: 5, distance: Frequency.MusicalDistance(cents: -10))
        let tunerData3 = TunerData(pitch: 820.0, amplitude: 0.3)

        return VStack(spacing: 50) {
            EQBarsView(match: match1, tunerData: tunerData1, eqBarCount: 5, eqMaxHeight: 100)
                .previewDisplayName("Strong Signal - In Tune")

            EQBarsView(match: match2, tunerData: tunerData2, eqBarCount: 7, eqMaxHeight: 80)
                .previewDisplayName("Medium Signal - Sharp")

            EQBarsView(match: match3, tunerData: tunerData3, eqBarCount: 3, eqMaxHeight: 120)
                .previewDisplayName("Weak Signal - Flat")
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color.gray.opacity(0.1))
    }
}
