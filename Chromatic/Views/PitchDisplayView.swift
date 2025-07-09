import SwiftUI

struct PitchDisplayView: View {
    let tunerData: TunerData
    let modifierPreference: ModifierPreference
    let selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    private let contentSpacing: CGFloat = 8
    private let noteTicksHeight: CGFloat = 100

    var body: some View {
        VStack(spacing: contentSpacing) {
            MatchedNoteView(match: match, modifierPreference: modifierPreference)
                .padding(.top, 5)
            MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                .padding(.bottom, 5)
            NoteTicks(tunerData: tunerData, showFrequencyText: true)
                .frame(height: noteTicksHeight)
                .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }
}
