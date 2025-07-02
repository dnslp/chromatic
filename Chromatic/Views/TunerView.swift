import SwiftUI

struct TunerView: View {
    let tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote
            .inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu")
    private var hidesTranspositionMenu = false

    // Layout constants
    private let watchHeight: CGFloat = 150
    private let nonWatchHeight: CGFloat = 300
    private let menuHeight: CGFloat = 44
    private let contentSpacing: CGFloat = 8

    var body: some View {
        Group {
        #if os(watchOS)
            ZStack(alignment: Alignment(horizontal: .noteCenter, vertical: .noteTickCenter)) {
                NoteTicks(tunerData: tunerData, showFrequencyText: false)
                MatchedNoteView(match: match, modifierPreference: modifierPreference)
                    .focusable()
                    .focusEffect(.none)
                    .focusStyle(.plain)
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
            .frame(height: watchHeight)
            .fixedSize()
        #else
            ZStack(alignment: .bottom) {
                // Top layer: tuning UI
                VStack(alignment: .noteCenter, spacing: contentSpacing) {
                    HStack {
                        if !hidesTranspositionMenu {
                            TranspositionMenu(selectedTransposition: $selectedTransposition)
                                .padding(.leading)
                        }
                        Spacer()
                    }
                    .frame(height: menuHeight)

                    MatchedNoteView(match: match, modifierPreference: modifierPreference)

                    MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)

                    NoteTicks(tunerData: tunerData, showFrequencyText: true)

                    Spacer()
                }

                // Bottom layer: fixed amplitude bar
                HStack(spacing: 8) {
                    Text("Level")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(height: 6)
                                .foregroundColor(Color.secondary.opacity(0.2))

                            Capsule()
                                .frame(
                                    width: geo.size.width * CGFloat(tunerData.amplitude),
                                    height: 6
                                )
                                .foregroundColor(
                                    Color(
                                        hue: 0.1 - 0.1 * tunerData.amplitude,
                                        saturation: 0.9,
                                        brightness: 0.9
                                    )
                                )
                                .animation(.easeInOut, value: tunerData.amplitude)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .frame(height: 20)
            }
            .frame(height: nonWatchHeight)
        #endif
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: TunerData(pitch: 440, amplitude: 0.5),
            modifierPreference: ModifierPreference.preferSharps,
            selectedTransposition: 0
        )
        .previewLayout(PreviewLayout.sizeThatFits)
        .padding()
    }
}
