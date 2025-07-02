import SwiftUI

/// Visualizer showing concentric circles filling based on pitch accuracy
struct ConcentricCircleVisualizer: View {
    let distance: Double        // Pitch deviation in cents
    let maxDistance: Double     // Max cents for full scale
    let tunerData: TunerData    // For dynamic styling

    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }

    private var fillColor: Color {
        let d = abs(distance)
        if d < 5 { return .green }
        else if d < 25 { return .yellow }
        else { return .red }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20 * tunerData.amplitude)
                .foregroundColor(.secondary)
                .frame(width: 100, height: 100)
            Circle()
                .frame(width: 100, height: 100)
                .scaleEffect(CGFloat(percent))
                .foregroundColor(fillColor.opacity(0.6))
                .animation(.easeInOut(duration: 0.2), value: percent)
        }
    }
}
