import SwiftUI
// Make sure MicrophonePitchDetector is available, e.g. if it's in a package.
// For previews, we'll use the MockPitchDetector defined in MicrophoneControlView.swift
// or define one locally if that's cleaner.

struct TunerView: View {
    // Pass the PitchDetector as an ObservedObject
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    let tunerData: TunerData // This will still be derived from pitchDetector in TunerScreen
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote
            .inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false

    // Layout constants
    private let watchHeight: CGFloat = 150
    private let nonWatchHeight: CGFloat = 460 // May need adjustment if adding more controls
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
            // watchOS UI remains unchanged as per current plan
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
            // iOS / macOS UI
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

                // Microphone Controls - Placed below Transposition Menu
                MicrophoneControlView(pitchDetector: pitchDetector)
                    .padding(.vertical, 8) // Add some vertical padding

                // Note display
                VStack(spacing: contentSpacing) {
                    MatchedNoteView(match: match, modifierPreference: modifierPreference)
                        .padding(.top, 100) // This padding might need review with new controls above
                    MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                        .padding(.bottom, 50)
                    NoteTicks(tunerData: tunerData, showFrequencyText: true)
                        .frame(height: noteTicksHeight)
                        .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                // Adjusted top padding because of the new MicrophoneControlView
                // The original .padding(.top, 60) on this VStack might be too much now.
                // Let's reduce it or manage spacing more carefully.
                // For now, let the internal paddings of MatchedNoteView handle its spacing.
                // .padding(.top, 60) // Commenting this out, review spacing
                .padding(.top, 20) // Reduced top padding

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
            // The nonWatchHeight might need to be increased to accommodate the new view.
            // Let's make it dynamic for now or increase it slightly.
            // .frame(height: nonWatchHeight) // Original fixed height
            .frame(minHeight: nonWatchHeight) // Use minHeight to allow expansion
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

// Define a MockPitchDetector for previews if not accessible from MicrophoneControlView's file
#if DEBUG
// This is often defined in the test target or in a shared testing utilities file.
// If MicrophoneControlView.swift already has MockPitchDetector, this isn't strictly necessary
// but doesn't hurt for TunerView's own previews.
class PreviewPitchDetector: MicrophonePitchDetector {
    override init() {
        super.init()
        // Setup initial states if needed for previews
        self.pitch = 440.0
        self.amplitude = 0.6
        self.didReceiveAudio = true
        self.microphoneState = .on
    }
}
#endif

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock pitch detector for the preview
        let mockPitchDetector = PreviewPitchDetector()

        // You can also create different mock detectors for different states
        let mockPitchDetectorPTT = PreviewPitchDetector()
        mockPitchDetectorPTT.microphoneState = .pushToTalk

        return Group {
            TunerView(
                pitchDetector: mockPitchDetector, // Pass the mock detector
                tunerData: TunerData(pitch: mockPitchDetector.pitch, amplitude: mockPitchDetector.amplitude),
                modifierPreference: ModifierPreference.preferSharps,
                selectedTransposition: 0
            )
            .previewDisplayName("State: On")

            TunerView(
                pitchDetector: mockPitchDetectorPTT, // Pass the mock detector for PTT
                tunerData: TunerData(pitch: mockPitchDetectorPTT.pitch, amplitude: mockPitchDetectorPTT.amplitude),
                modifierPreference: ModifierPreference.preferSharps,
                selectedTransposition: 0
            )
            .previewDisplayName("State: PushToTalk")
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemGray5)) // Added background to see card clearly
    }
}
