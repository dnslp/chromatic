import SwiftUI

struct TunerView: View {
    let tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu")
    private var hidesTranspositionMenu = false

    // Fixed heights to stabilize layout
    private let watchHeight: CGFloat = 150
    private let nonWatchHeight: CGFloat = 300
    private let menuHeight: CGFloat = 44
    private let contentSpacing: CGFloat = 8


    struct PulsingCircle: View {
        /// Expected 0…1
        var amplitude: Double
        /// Maximum extra scale (e.g. 0.5 = up to 150%)
        var maxScale: CGFloat = 0.5

        var body: some View {
            Circle()
                .fill(Color.accentColor.opacity(0.4))
                .frame(width: 100, height: 100)
                .scaleEffect(1 + CGFloat(amplitude) * maxScale)
                .animation(.easeOut(duration: 0.2), value: amplitude)
                .shadow(radius: CGFloat(amplitude) * 10)
        }
    }

    var body: some View {
        Group {
#if os(watchOS)
            ZStack(alignment: Alignment(horizontal: .noteCenter, vertical: .noteTickCenter)) {
                NoteTicks(tunerData: tunerData, showFrequencyText: false)
                MatchedNoteView(
                    match: match,
                    modifierPreference: modifierPreference
                )
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
            VStack(alignment: .noteCenter, spacing: contentSpacing) {
                HStack {
                    if !hidesTranspositionMenu {
                        TranspositionMenu(selectedTransposition: $selectedTransposition)
                            .padding(.leading)
                    }
                    Spacer()
                }
                .frame(height: menuHeight)

                MatchedNoteView(
                    match: match,
                    modifierPreference: modifierPreference
                )

                MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)

                NoteTicks(tunerData: tunerData, showFrequencyText: true)

                VStack(spacing: 16) {
                  // … your existing note display, ticks, etc. …

                  // Pulsing Circle
                  PulsingCircle(amplitude: tunerData.amplitude)
                    .padding(.top, 8)

                  // (Optional) numeric read-out below
                  Text("Level: \(tunerData.amplitude, specifier: "%.2f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)
            }
            .frame(height: nonWatchHeight, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
#endif
        }
        // Stick to top of containing layout
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: TunerData(pitch: 440, amplitude: 0.5),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
