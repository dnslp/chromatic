import SwiftUI

/// Marks the current detected note position in the tick view
struct CurrentNoteMarker: View {
    let frequency: Frequency
    let distance: Frequency.MusicalDistance
    let showFrequencyText: Bool

    // Fixed dimensions
    private let tickHeight: CGFloat = NoteTickSize.large.height
    private let textHeight: CGFloat = 20
    private var totalHeight: CGFloat {
        tickHeight + (showFrequencyText ? textHeight + 4 : 0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Marker line
                Rectangle()
                    .fill(distance.isPerceptible ? Color.perceptibleMusicalDistance : Color.imperceptibleMusicalDistance)
                    .frame(width: 4, height: tickHeight)
                    .position(
                        x: geo.size.width/2 + (CGFloat(distance.cents)/50) * (geo.size.width/2),
                        y: tickHeight/2
                    )

                // Optional frequency text
                if showFrequencyText {
                    Text(frequency.localizedString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: geo.size.width)
                        .position(
                            x: geo.size.width/2 + (CGFloat(distance.cents)/50) * (geo.size.width/2),
                            y: tickHeight + textHeight/2 + 4
                        )
                }
            }
        }
        .frame(height: totalHeight)
        .fixedSize(horizontal: false, vertical: true)
        .alignmentGuide(.noteTickCenter) { $0[VerticalAlignment.center] }
    }
}

struct CurrentNoteMarker_Previews: PreviewProvider {
    static var previews: some View {
        CurrentNoteMarker(
            frequency: 440.0,
            distance: Frequency.MusicalDistance(cents: 25),
            showFrequencyText: true
        )
        .previewLayout(.fixed(width: 300, height: 200))
    }
}
