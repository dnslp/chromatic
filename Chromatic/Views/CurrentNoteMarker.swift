import SwiftUI

struct CurrentNoteMarker: View {
    let frequency: Frequency
    let distance: Frequency.MusicalDistance
    let showFrequencyText: Bool

    // Marker constants for stable layout
    private let markerWidth: CGFloat = 15
    private let markerHeight: CGFloat = 120
    private let labelHeight: CGFloat = 1
    private let totalWidth: CGFloat = 36  // marker + fudge for text
    private let totalHeight: CGFloat = 100

    var body: some View {
        GeometryReader { geometry in
            // Overlay marker at the horizontal offset, *not* affecting the layout of the parent
            ZStack(alignment: .topLeading) {
                // This is an invisible bar that "reserves" the space so the parent never resizes
                Color.clear
                    .frame(width: geometry.size.width, height: totalHeight)
                // The moving marker
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(width: markerWidth, height: markerHeight)
                        .cornerRadius(markerWidth / 2)
                        .foregroundColor(
                            distance.isPerceptible ? .perceptibleMusicalDistance : .imperceptibleMusicalDistance
                        )

//                    
                }
                .frame(width: totalWidth)
                // The magic: move only this view left/right, don't shift parent/container
                .position(
                    x: (geometry.size.width / 2) * CGFloat(distance.cents / 50) + geometry.size.width / 2,
                    y: totalHeight / 2
                )
                .animation(.easeInOut(duration: 0.12), value: distance.cents)
            }
            .frame(height: totalHeight)
            // Frequency label is always present, just hidden when not needed
            Text(frequency.localizedString())
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)           // Take the full horizontal space
                .multilineTextAlignment(.center)      // Center the text horizontally
                .padding(.top, 140)                     // Space above, adjust as needed

        }
        .frame(height: 60) // Always the same, matches totalHeight above
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
        .previewLayout(.fixed(width: 300, height: 300))
    }
}
