import SwiftUI

struct EQBarsView: View {
    let match: ScaleNote.Match
    let tunerData: TunerData
    let eqBarCount: Int
    let eqMaxHeight: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 22) {
            ForEach(0..<eqBarCount, id: \.self) { i in
                let d = abs(match.distance.cents)
                let c: Color = d < 5 ? .green : (d < 25 ? .yellow : .red)
                let center = Double(eqBarCount - 1) / 2
                let factor = 1.5 - abs(Double(i) - center) / center
                let height = eqMaxHeight * CGFloat(tunerData.amplitude) * CGFloat(factor)
                Capsule()
                    .frame(width: 8, height: height)
                    .foregroundColor(c)
                    .animation(.easeInOut(duration: 0.2), value: tunerData.amplitude)
            }
        }
        .frame(height: eqMaxHeight)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 25)
        .padding(.bottom, 35)
    }
}
