import SwiftUI

struct TunerView: View {
    let tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote
            .inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false

    // Layout constants
    private let watchHeight: CGFloat = 150
    private let nonWatchHeight: CGFloat = 460
    private let menuHeight: CGFloat = 44
    private let contentSpacing: CGFloat = 8
    private let noteTicksHeight: CGFloat = 100
    private let amplitudeBarHeight: CGFloat = 32

    // EQ settings
    private let eqBarCount: Int = 10
    private let eqMaxHeight: CGFloat = 90
    private let maxCentDistance: Double = 50

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
                        Binding(get: { Float(selectedTransposition) }, set: { selectedTransposition = Int($0) }),
                        from: 0, through: Float(ScaleNote.allCases.count - 1), by: 1
                    )
            }
            .frame(height: watchHeight)
            .fixedSize()
        #else
            VStack(spacing: 0) {
                // Header/Menu
                HStack {
                    if !hidesTranspositionMenu {
                        TranspositionMenu(selectedTransposition: $selectedTransposition)
                            .padding(.leading, 8)
                    }
                    Spacer()
                }
                .frame(height: menuHeight)

                // Note display
                VStack(spacing: contentSpacing) {
                    MatchedNoteView(match: match, modifierPreference: modifierPreference)
                        .padding(.top, 100)
                    MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                        .padding(.bottom, 50)
                    NoteTicks(tunerData: tunerData, showFrequencyText: true)
                        .frame(height: noteTicksHeight)
                        .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.top, 60)

                Spacer(minLength: 24)

                // Concentric tuner
                ConcentricCircleVisualizer(
                    distance: Double(match.distance.cents),
                    maxDistance: maxCentDistance,
                    tunerData: tunerData
                )
                .frame(width: 100, height: 100)
                .padding(.bottom, 16)

                // Pitch-on-line visualizer
                PitchLineVisualizer(tunerData: tunerData, frequency: tunerData.pitch)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // EQ bars
                EQBarsView(
                    match: match,
                    tunerData: tunerData,
                    eqBarCount: eqBarCount,
                    eqMaxHeight: eqMaxHeight
                )

                // Amplitude bar
                HStack(spacing: 8) {
                    Text("Level").font(.caption2).foregroundColor(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(height: 6)
                                .foregroundColor(Color.secondary.opacity(0.14))
                            Capsule()
                                .frame(width: geo.size.width * CGFloat(tunerData.amplitude), height: 6)
                                .foregroundColor(
                                    Color(hue: 0.1 - 0.1 * tunerData.amplitude, saturation: 0.9, brightness: 0.9)
                                )
                                .animation(.easeInOut, value: tunerData.amplitude)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .frame(height: amplitudeBarHeight)
                .background(Color(.systemBackground).opacity(0.85))
                .cornerRadius(8)
                .shadow(radius: 2, y: -1)
                .padding(.top, 0)
            }
            .frame(height: nonWatchHeight)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.94))
                    .shadow(color: Color.black.opacity(0.05), radius: 16, y: 4)
            )
            .padding(.horizontal, 8)
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
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
