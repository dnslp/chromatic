import SwiftUI

struct NoteTicks: View {
    let tunerData: TunerData
    let showFrequencyText: Bool

    var body: some View {
        NoteDistanceMarkers(tunerData: tunerData)
            .overlay(
                CurrentNoteMarker(
                    frequency: tunerData.pitch,
                    distance: tunerData.closestNote.distance,
                    showFrequencyText: showFrequencyText
                )
            )
    }
}

struct NoteTicks_Previews: PreviewProvider {
    static var previews: some View {
        let tunerDataInTune = TunerData(pitch: 440.0, amplitude: 0.7)
        let tunerDataSharp = TunerData(pitch: 445.5, amplitude: 0.6) // Approx +22 cents
        let tunerDataFlat = TunerData(pitch: 432.1, amplitude: 0.8)   // Approx -31 cents

        return Group {
            NoteTicks(tunerData: tunerDataInTune, showFrequencyText: true)
                .previewDisplayName("In Tune, Show Text")
                .padding()
                .background(Color.gray.opacity(0.1))

            NoteTicks(tunerData: tunerDataSharp, showFrequencyText: false)
                .previewDisplayName("Sharp, No Text")
                .padding()
                .background(Color.gray.opacity(0.1))

            NoteTicks(tunerData: tunerDataFlat, showFrequencyText: true)
                .previewDisplayName("Flat, Show Text")
                .padding()
                .background(Color.gray.opacity(0.1))
        }
        .previewLayout(.fixed(width: 250, height: 400))
    }
}
