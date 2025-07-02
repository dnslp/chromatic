import SwiftUI

/// Visualizer showing current input pitch position on a horizontal line (55–1100 Hz)
struct PitchLineVisualizer: View {
    let tunerData: TunerData
    let frequency: Frequency
    let minHz: Double = 55
    let maxHz: Double = 440

    private var percent: Double {
        let hz = frequency.measurement.value
      return min(max((hz - minHz)/(maxHz - minHz), 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 4)
                    .foregroundColor(.secondary)
                Circle()
                    .frame(width: 16, height: 16)
                    .offset(x: CGFloat(percent) * (geo.size.width - 16))
                    .foregroundColor(.accentColor)
                    .animation(.easeInOut(duration: 0.2), value: percent)
            }
        }
        .frame(height: 20)
    }
}
