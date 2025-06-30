import SwiftUI

struct NoteDistanceMarkers: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Existing ticks
                HStack {
                    ForEach(0..<25) { index in
                        Rectangle()
                            .frame(width: 1, height: tickSize(forIndex: index).height)
                            .cornerRadius(1)
                            .foregroundColor(.secondary)
                            .inExpandingRectangle()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Threshold markers
                let thresholdOffset = (geometry.size.width / 2) * CGFloat(Frequency.MusicalDistance.perceptibilityThreshold / 50)
                let markerHeight = NoteTickSize.medium.height // Or choose a specific height

                // Negative threshold marker
                Rectangle()
                    .frame(width: 1.5, height: markerHeight) // Slightly thicker or different style
                    .cornerRadius(0.75)
                    .foregroundColor(Color.gray.opacity(0.6))
                    .offset(x: -thresholdOffset)

                // Positive threshold marker
                Rectangle()
                    .frame(width: 1.5, height: markerHeight)
                    .cornerRadius(0.75)
                    .foregroundColor(Color.gray.opacity(0.6))
                    .offset(x: thresholdOffset)
            }
        }
        .frame(height: NoteTickSize.large.height) // Ensure GeometryReader has a defined height
        .alignmentGuide(.noteTickCenter) { dimensions in
            dimensions[VerticalAlignment.center]
        }
    }

    private func tickSize(forIndex index: Int) -> NoteTickSize {
        switch index {
        case 12:           .large
        case 2, 7, 17, 22: .medium
        default:           .small
        }
    }
}

enum NoteTickSize {
    case small, medium, large

    var height: CGFloat {
        switch self {
        case .small:  60
        case .medium: 100
        case .large:  180
        }
    }
}

extension View {
    func inExpandingRectangle() -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
            self
        }
    }
}

struct NoteDistanceMarkers_Previews: PreviewProvider {
    static var previews: some View {
        NoteDistanceMarkers()
            .previewLayout(.sizeThatFits)
    }
}
