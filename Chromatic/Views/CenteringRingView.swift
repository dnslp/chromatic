import SwiftUI

struct CenteringRingView: View {
    let tunerData: TunerData
    let selectedTransposition: Int
    let userF0: Double

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    private let maxCentDistance: Double = 50

    var body: some View {
        ConcentricCircleVisualizer(
            distance: Double(match.distance.cents),
            maxDistance: maxCentDistance,
            tunerData: tunerData,
            fundamentalHz: userF0
        )
        .frame(width: 100, height: 100)
        .padding(.bottom, 2)
    }
}
