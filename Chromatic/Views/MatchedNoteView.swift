import SwiftUI

struct MatchedNoteView: View {
    let match: ScaleNote.Match
    @State var modifierPreference: ModifierPreference

    var body: some View {
        ZStack(alignment: .noteModifier) {
            HStack(alignment: .lastTextBaseline) {
                MainNoteView(note: note)
                    .animation(nil, value: note) // Don't animate text frame
                    .animatingMusicalDistanceForegroundColor(distance: match.distance)
                Text(String(describing: match.octave))
                    .alignmentGuide(.octaveCenter) { dimensions in
                        dimensions[HorizontalAlignment.center]
                    }
                    // TODO: Avoid hardcoding size
                    .font(.system(size: 20, design: .rounded))
                    .foregroundColor(.secondary)
            }

            if let modifier = modifier {
                Text(modifier)
                    // TODO: Avoid hardcoding size
                    .font(.system(size: 50, design: .rounded))
                    .baselineOffset(-30) // TODO: Find a better way to align top of text - FB9267771
                    .animatingMusicalDistanceForegroundColor(distance: match.distance)
                    .alignmentGuide(.octaveCenter) { dimensions in
                        dimensions[HorizontalAlignment.center]
                    }
            }
        }
        .padding(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15)) // Add some padding around the text
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColorForDistance(match.distance))
        )
        .animation(.easeInOut, value: match.distance.cents) // Animate based on the cents value
        .onTapGesture {
            modifierPreference = modifierPreference.toggled
        }
    }

    private var preferredName: String {
        switch modifierPreference {
        case .preferSharps:
            match.note.names.first!
        case .preferFlats:
            match.note.names.last!
        }
    }

    private var note: String {
        String(preferredName.prefix(1))
    }

    private var modifier: String? {
        preferredName.count > 1 ?
            String(preferredName.suffix(1)) :
            nil
    }

    private func backgroundColorForDistance(_ distance: Frequency.MusicalDistance) -> Color {
        // Using the centralized color logic and applying opacity
        return Color.color(for: distance).opacity(0.15)
    }
}

private extension View {
    // Removed @ViewBuilder as it's not needed for this type of modifier
    // and was likely causing the buildExpression error.
    func animatingMusicalDistanceForegroundColor(distance: Frequency.MusicalDistance) -> some View {
        // Using the centralized color logic
        return self.foregroundColor(Color.color(for: distance))
    }
}

struct MatchedNoteView_Previews: PreviewProvider {
    static var previews: some View {
        MatchedNoteView(
            match: ScaleNote.Match(
                note: .ASharp_BFlat,
                octave: 4,
                distance: 0
            ),
            modifierPreference: .preferSharps
        )
        .previewLayout(.sizeThatFits)
    }
}
