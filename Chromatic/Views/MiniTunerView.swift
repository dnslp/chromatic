import SwiftUI

struct MiniTunerView: View {
    let tunerData: TunerData
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    var body: some View {
        VStack(alignment: .noteCenter) {
            MatchedNoteView(
                match: match,
                modifierPreference: modifierPreference
            )
            // Removed MatchedNoteFrequency for a "mini" version
            NoteTicks(tunerData: tunerData, showFrequencyText: false) // showFrequencyText is false for mini version
        }
        .padding(.vertical) // Add some padding to space it out in PlayerView
    }
}

struct MiniTunerView_Previews: PreviewProvider {
    static var previews: some View {
        MiniTunerView(
            tunerData: TunerData(pitch: 440, amplitude: 0.5),
            modifierPreference: .constant(.preferSharps),
            selectedTransposition: .constant(0)
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
