import SwiftUI
import AVFoundation     // NEW

// MARK: - Extended Pitch Statistics Models & Helpers
/// Encapsulates descriptive statistics for a recording session's pitch data
struct PitchStatistics {
    /// Lowest pitch recorded (Hz)
    let min: Double  // reveals bottom range
    /// Highest pitch recorded (Hz)
    let max: Double  // reveals top range
    /// Mean pitch (Hz)
    let avg: Double  // bias flat vs. sharp
    /// Median pitch (Hz)
    let median: Double  // robust center
    /// Standard deviation of pitch (Hz)
    let stdDev: Double  // stability measure
    /// Interquartile range (Hz)
    let iqr: Double  // midspread
    /// Root-mean-square pitch (Hz)
    let rms: Double  // weighted deviations
    
    /// Returns percentage within ±toleranceCents of target (cents)
    func percentWithin(target: Double, toleranceCents: Double, values: [Double]) -> Double {
        let within = values.filter { frequency in
            let centsDiff = 1200 * log2(frequency / target)
            return abs(centsDiff) <= toleranceCents
        }
        return values.isEmpty ? 0 : Double(within.count) / Double(values.count) * 100
    }
}

// SessionStatistics now holds both stats and duration
struct SessionStatistics {
    let pitch: PitchStatistics
    let duration: TimeInterval
}

extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
    var median: Double? {
        guard !isEmpty else { return nil }
        let s = sorted()
        let m = count / 2
        return count.isMultiple(of: 2) ? (s[m-1] + s[m]) / 2 : s[m]
    }
    var standardDeviation: Double? {
        guard let mu = average else { return nil }
        let sum = reduce(0) { $0 + pow($1 - mu, 2) }
        return sqrt(sum / Double(count))
    }
    var quartiles: (q1: Double, q3: Double)? {
        guard count >= 4 else { return nil }
        let s = sorted()
        return (s[count/4], s[3*count/4])
    }
    var iqr: Double? {
        guard let qs = quartiles else { return nil }
        return qs.q3 - qs.q1
    }
    var rms: Double? {
        guard !isEmpty else { return nil }
        let sum = reduce(0) { $0 + $1 * $1 }
        return sqrt(sum / Double(count))
    }
}

// MARK: - Stats Modal View
struct StatsModalView: View {
    let statistics: PitchStatistics
    let duration: TimeInterval
    let values: [Double]
    @Environment(\.dismiss) private var dismiss

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
        NavigationView {
            List {
                Section("Session Info") {
                    let safeDuration = max(0, duration)
                    Text("Duration: \(formatTime(safeDuration))")
                }
                Section("Pitch Range & Central Tendency") {
                    Text(String(format: "Min: %.2f Hz", statistics.min))
                    Text(String(format: "Max: %.2f Hz", statistics.max))
                    Text(String(format: "Avg: %.2f Hz", statistics.avg))
                    Text(String(format: "Median: %.2f Hz", statistics.median))
                }
                Section("Variability Measures") {
                    Text(String(format: "Std Dev: %.2f Hz", statistics.stdDev))
                    Text(String(format: "IQR: %.2f Hz", statistics.iqr))
                    Text(String(format: "RMS: %.2f Hz", statistics.rms))
                }
                Section("Tuning Accuracy") {
                    let pct = statistics.percentWithin(
                        target: values.average ?? 0,
                        toleranceCents: 5,
                        values: values)
                    Text(String(format: "Within ±5¢: %.1f%%", pct))
                }
            }
            .navigationTitle("Session Statistics")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

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

// MARK: - Extended calculateStatistics on TunerData
extension TunerData {
    func calculateStatisticsExtended(duration: TimeInterval) -> SessionStatistics? {
        let vals = recordedPitches
        guard !vals.isEmpty,
              let min = vals.min(), let max = vals.max(),
              let avg = vals.average, let med = vals.median,
              let sd = vals.standardDeviation, let iqr = vals.iqr,
              let rms = vals.rms
        else { return nil }
        let stats = PitchStatistics(
            min: min, max: max, avg: avg,
            median: med, stdDev: sd,
            iqr: iqr, rms: rms
        )
        return SessionStatistics(pitch: stats, duration: duration)
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
