import SwiftUI

/// Visualizer showing concentric circles filling based on pitch accuracy
struct ConcentricCircleVisualizer: View {
    let distance: Double        // Pitch deviation in cents
    let maxDistance: Double     // Max cents for full scale
    let tunerData: TunerData    // For dynamic styling

    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }

    private var fillColor: Color {
        let d = abs(distance)
        if d < 5 { return .green }
        else if d < 25 { return .yellow }
        else { return .red }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20 * tunerData.amplitude)
                .foregroundColor(.secondary)
                .frame(width: 100, height: 100)
            Circle()
                .frame(width: 100, height: 100)
                .scaleEffect(CGFloat(percent))
                .foregroundColor(fillColor.opacity(0.6))
                .animation(.easeInOut(duration: 0.2), value: percent)
        }
    }
}

/// Visualizer showing current input pitch position on a horizontal line (55–1100 Hz)
struct PitchLineVisualizer: View {
    let tunerData: TunerData
    let frequency: Frequency
    let minHz: Double = 55
    let maxHz: Double = 440

    private var percent: Double {
        let hz = frequency.measurement.value
      return min(max((hz - minHz)/(maxHz - minHz), 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 4)
                    .foregroundColor(.secondary)
                Circle()
                    .frame(width: 16, height: 16)
                    .offset(x: CGFloat(percent) * (geo.size.width - 16))
                    .foregroundColor(.accentColor)
                    .animation(.easeInOut(duration: 0.2), value: percent)
            }
        }
        .frame(height: 20)
    }
}

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
                HStack(alignment: .bottom, spacing: 22) {
                    ForEach(0..<eqBarCount, id: \.self) { i in
                        let d = abs(match.distance.cents)
                        let c: Color = d < 5 ? .green : (d < 25 ? .yellow : .red)
                        let center = Double(eqBarCount - 1) / 2
                        let factor = 1.5 - abs(Double(i) - center) / center
                        let height = eqMaxHeight * CGFloat(tunerData.amplitude) * CGFloat(factor)
                        Capsule()
                            .frame(width: 8, height: height)
                            .foregroundColor(c)
                            .animation(.easeInOut(duration: 0.2), value: tunerData.amplitude)
                    }
                }
                .frame(height: eqMaxHeight)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 25)
                .padding(.bottom, 35)

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
