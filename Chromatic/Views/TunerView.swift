import SwiftUI

struct TunerView: View {
    let tunerData: TunerData
    let micIsActive: Bool // Added to receive mic status
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu")
    private var hidesTranspositionMenu = false

    var body: some View {
#if os(watchOS)
        ZStack(alignment: Alignment(horizontal: .noteCenter, vertical: .noteTickCenter)) {
            NoteTicks(tunerData: tunerData, showFrequencyText: false)

            MatchedNoteView(
                match: match,
                modifierPreference: modifierPreference
            )
            .focusable()
            .digitalCrownRotation(
                Binding(
                    get: { Float(selectedTransposition) },
                    set: { selectedTransposition = Int($0) }
                ),
                from: 0,
                through: Float(ScaleNote.allCases.count - 1),
                by: 1
            )
        }
#else
        VStack(alignment: .noteCenter) {
            if !hidesTranspositionMenu {
                HStack {
                    TranspositionMenu(selectedTransposition: $selectedTransposition)
                        .padding(.leading)

                    Spacer() // Pushes mic icon to the right if transposition menu is visible

                    Image(systemName: "mic.fill")
                        .foregroundColor(micIsActive ? .green : .gray)
                        .padding(.trailing)
                }
                .padding(.top) // Add some padding at the top
            } else {
                // If transposition menu is hidden, still show the mic icon, perhaps top right
                HStack {
                    Spacer()
                    Image(systemName: "mic.fill")
                        .foregroundColor(micIsActive ? .green : .gray)
                        .padding([.top, .trailing])
                }
            }

            Spacer()

            MatchedNoteView(
                match: match,
                modifierPreference: modifierPreference
            )

            MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)

            NoteTicks(tunerData: tunerData, showFrequencyText: true)

            // Amplitude Meter
            VStack {
                Text("Input Level")
                    .font(.caption)
                ProgressView(value: tunerData.amplitude, total: 1.0) // Assuming amplitude is 0.0 to 1.0
                    .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                    .frame(height: 10) // Adjust height as needed
                    .padding(.horizontal)
                    // Clamp amplitude to ensure it's within 0-1 for ProgressView
                    // ProgressView(value: min(max(tunerData.amplitude, 0.0), 1.0), total: 1.0)
            }
            .padding()

            Spacer()
        }
#endif
    }
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: TunerData(pitch: 440, amplitude: 0.5),
            micIsActive: true, // Added for preview
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .previewDisplayName("Active Mic")

        TunerView(
            tunerData: TunerData(pitch: 440, amplitude: 0.1),
            micIsActive: false, // Added for preview
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .previewDisplayName("Inactive Mic")
    }
}
