import SwiftUI
import AVFoundation     // NEW

// MARK: - TunerView
struct TunerView: View {
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    @State private var userF0: Double = 77.78
    @State private var micMuted = false
    @State private var sessionStats: SessionStatistics?   // Updated!
    @State private var showStatsModal = false

    // Timer State
    @State private var recordingStartedAt: Date?
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var elapsed: TimeInterval {
        guard let start = recordingStartedAt else { return 0 }
        return Date().timeIntervalSince(start)
    }

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false

    // Layout constants
    private let watchHeight: CGFloat = 150
    private let nonWatchHeight: CGFloat = 560
    private let menuHeight: CGFloat = 44
    private let contentSpacing: CGFloat = 8
    private let noteTicksHeight: CGFloat = 100
    private let amplitudeBarHeight: CGFloat = 32
    private let maxCentDistance: Double = 50

    // Helper to format time as MM:SS or H:MM:SS
    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        Group {
        #if os(watchOS)
            // watchOS unchanged...
            ZStack { /* ... */ }
        #else
            HStack(spacing: 1) {
                // ────────── VERTICAL VISUALIZER ──────────
                PitchLineVisualizer(
                    tunerData: tunerData,
                    frequency: tunerData.pitch,
                    fundamental: Frequency(floatLiteral: userF0)
                )
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
                                                     .frame(
                                                         width: geo.size.width *
                                                             CGFloat(micMuted ? 0 : tunerData.amplitude),
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
                                             .padding(.top, 50)
                                         MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                                             .padding(.bottom, 50)
                                         NoteTicks(tunerData: tunerData, showFrequencyText: true)
                                             .frame(height: noteTicksHeight)
                                             .padding(.vertical, 2)
                                     }
                                     .frame(maxWidth: .infinity)
                                     .padding(.horizontal, 12)
                                     .padding(.top, 40)

                                     Spacer(minLength: 40)

                                     // ───── OTHER VISUALIZERS ─────
                                     ConcentricCircleVisualizer(
                                         distance: Double(match.distance.cents),
                                         maxDistance: maxCentDistance,
                                         tunerData: tunerData,
                                         fundamentalHz: userF0
                                     )
                                     .frame(width: 100, height: 100)
                                     .padding(.bottom, 20)

                                     HarmonicGraphView(tunerData: tunerData)
                                         .frame(height: 30)

                    // MARK: RECORD / STATS WITH TIMER
                    VStack(alignment: .leading, spacing: 6) {
                        // Show timer only when recording, never negative
                        if let startedAt = recordingStartedAt, elapsed >= 0 {
                            Text("Recording: \(formatTime(elapsed))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 16) {
                            Button(action: {
                                if tunerData.isRecording {
                                    tunerData.stopRecording()
                                    // Always use the most up-to-date time for the session duration!
                                    let sessionDuration = Date().timeIntervalSince(recordingStartedAt ?? Date())
                                    sessionStats = tunerData.calculateStatisticsExtended(duration: max(0, sessionDuration))
                                    showStatsModal = true
                                    recordingStartedAt = nil
                                } else {
                                    tunerData.startRecording()
                                    sessionStats = nil
                                    recordingStartedAt = Date()
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
                                sessionStats = nil
                                recordingStartedAt = nil
                            }) {
                                Text("Clear Data")
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .sheet(isPresented: $showStatsModal) {
                            if let stats = sessionStats {
                                StatsModalView(
                                    statistics: stats.pitch,
                                    duration: stats.duration,
                                    values: tunerData.recordedPitches
                                )
                            }
                        }
                    }
                    .onReceive(ticker) { current in
                        // Not strictly needed, but you can keep for legacy logic or display updates
                        if recordingStartedAt != nil {
                            now = current
                        }
                    }
                    .padding(.horizontal)

                    // ────────── TRANSPOSE MENU ──────────
                    HStack {
                        F0SelectorView(f0Hz: $userF0)
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
}

// MARK: - TunerView Preview
struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: .constant(TunerData(pitch: 428, amplitude: 0.5)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
