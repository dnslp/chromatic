import SwiftUI
import AVFoundation     // NEW

struct TunerView: View {
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    
    

    // NEW – mic-mute toggle
    @State private var micMuted = false

    // Statistics for the recording feature
    @State private var statistics: (min: Double, max: Double, avg: Double)?

    private var match: ScaleNote.Match {
        tunerData.closestNote
            .inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false

    // Layout constants
    private let watchHeight: CGFloat = 150
    private let nonWatchHeight: CGFloat = 560
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
            // —— watchOS layout unchanged ——
            ZStack(alignment: Alignment(horizontal: .noteCenter, vertical: .noteTickCenter)) {
                NoteTicks(tunerData: tunerData, showFrequencyText: false)
                MatchedNoteView(match: match, modifierPreference: modifierPreference)
                    .focusable()
                    .focusEffect(.none)
                    .focusStyle(.plain)
                    .digitalCrownRotation(
                        Binding(get: { Float(selectedTransposition) },
                                set: { selectedTransposition = Int($0) }),
                        from: 0, through: Float(ScaleNote.allCases.count - 1), by: 1
                    )
            }
            .frame(height: watchHeight)
            .fixedSize()
        #else
            HStack(alignment: .center, spacing: 1) {
                // ────────── VERTICAL VISUALIZER ──────────
                PitchLineVisualizer(tunerData: tunerData, frequency: tunerData.pitch)
                    .frame(width: 10)
                    .padding(.vertical, 16)

                // ────────── MAIN CONTENT ──────────
                VStack(spacing: 0) {
                    // ───── AMPLITUDE BAR ─────
                    HStack(spacing: 8) {
                        Text("Level")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .frame(height: 6)
                                    .foregroundColor(Color.secondary.opacity(0.14))
                                Capsule()
                                    .frame(width: geo.size.width * CGFloat(micMuted ? 0 : tunerData.amplitude),
                                           height: 6)
                                    .foregroundColor(
                                        Color(hue: 0.1 - 0.1 * tunerData.amplitude,
                                              saturation: 0.9,
                                              brightness: 0.9)
                                    )
                                    .animation(.easeInOut, value: tunerData.amplitude)
                            }
                        }
                        .frame(height: amplitudeBarHeight)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: amplitudeBarHeight)
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(8)
                    .shadow(radius: 2, y: -1)
                    
                    // ───── NOTE DISPLAY ─────
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

                    Spacer(minLength: 30)

                    // ───── OTHER VISUALIZERS ─────
                    ConcentricCircleVisualizer(
                        distance: Double(match.distance.cents),
                        maxDistance: maxCentDistance,
                        tunerData: tunerData
                    )
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 20)

                    HarmonicGraphView(tunerData: tunerData)
                        .frame(height: 30)

                    // ───── RECORD / STATS ─────
                    VStack {
                        HStack {
                            Button(action: {
                                if tunerData.isRecording {
                                    tunerData.stopRecording()
                                    statistics = tunerData.calculateStatistics()
                                } else {
                                    tunerData.startRecording()
                                    statistics = nil
                                }
                            }) {
                                Text(tunerData.isRecording ? "Stop Recording" : "Start Recording")
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(tunerData.isRecording ? Color.red : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }

                            Button(action: {
                                tunerData.clearRecording()
                                statistics = nil
                            }) {
                                Text("Clear Data")
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 8)

                        if let stats = statistics {
                            VStack(alignment: .leading) {
                                Text(String(format: "Min: %.2f Hz (%@)", stats.min,
                                            formatPitchAndCents(frequency: stats.min)))
                                Text(String(format: "Max: %.2f Hz (%@)", stats.max,
                                            formatPitchAndCents(frequency: stats.max)))
                                Text(String(format: "Avg: %.2f Hz (%@)", stats.avg,
                                            formatPitchAndCents(frequency: stats.avg)))
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // ───── TRANSPOSE MENU ─────
                    HStack {
                        if !hidesTranspositionMenu {
                            TranspositionMenu(selectedTransposition: $selectedTransposition)
                                .padding(.leading, 8)
                        }
                        Spacer()
                    }
                    .frame(height: menuHeight)
                }
                .frame(maxWidth: .infinity)
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

    // MARK: - Mic control helpers
    private func toggleMicMute() {
        micMuted ? unmuteMicrophone() : muteMicrophone()
        micMuted.toggle()
    }

    private func muteMicrophone() {
        let session = AVAudioSession.sharedInstance()
        guard session.isInputGainSettable else { return }
        try? session.setInputGain(0)
    }

    private func unmuteMicrophone() {
        let session = AVAudioSession.sharedInstance()
        guard session.isInputGainSettable else { return }
        try? session.setInputGain(1)
    }

    // MARK: - Utility
    private func formatPitchAndCents(frequency: Double) -> String {
        let freq = Frequency(floatLiteral: frequency)
        let match = ScaleNote.closestNote(to: freq)
        let cents = match.distance.cents
        let centsString = String(format: "%+.0f cents", cents)
        let pitchName = "\(match.note.names.first ?? "")\(match.octave)"
        return "\(pitchName) \(centsString)"
    }
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: .constant(TunerData(pitch: 440, amplitude: 0.5)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
