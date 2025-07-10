import SwiftUI

// MARK: - Stats Modal View
struct StatsModalView: View {
    @EnvironmentObject var sessionStore: SessionStore
    let statistics: PitchStatistics
    let duration: TimeInterval
    let values: [Double]
    let profileName: String // Added profileName property
    @Environment(\.dismiss) private var dismiss

    // --- VoicePrint visual summary for this session
    private var voicePrintStats: VoicePrintStats {
        VoicePrintStats.fromSession(
            pitches: values,
            amplitudes: Array(repeating: 0.8, count: values.count), // Substitute with real amplitudes if available
            start: Date(), // Replace with actual session start if available
            end: Date().addingTimeInterval(duration),
            inTuneHz: statistics.avg
        )
    }

    // Helper to find the closest pitch and cents difference for a given frequency
    private func closestPitchInfo(to frequency: Double) -> (name: String, centsDifference: Double) {
        guard !pitchFrequencies.isEmpty else { return ("N/A", 0.0) }
        var closestPitch = pitchFrequencies[0]
        var smallestAbsDifference = abs(pitchFrequencies[0].frequency - frequency)
        for pitch in pitchFrequencies.dropFirst() {
            let absDifference = abs(pitch.frequency - frequency)
            if absDifference < smallestAbsDifference {
                smallestAbsDifference = absDifference
                closestPitch = pitch
            }
        }
        let centsDifference = 1200 * log2(frequency / closestPitch.frequency)
        // Prefer sharps for display if dual-named
        let name = closestPitch.name.components(separatedBy: "/").first ?? closestPitch.name
        return (name, centsDifference)
    }

    // Helper to format cents difference
    private func formatCents(_ cents: Double) -> String {
        let roundedCents = Int(round(cents))
        return String(format: "%+d", roundedCents)
    }

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
                // --- Visual summary at the top ---
                VoicePr(stats: voicePrintStats)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                Section("Session Info") {
                    let safeDuration = max(0, duration)
                    Text("Duration: \(formatTime(safeDuration))")
                    Text("Profile: \(profileName)")
                }
                Section("Pitch Range & Central Tendency") {
                    let minInfo = closestPitchInfo(to: statistics.min)
                    Text(String(format: "Min: %.2f Hz (%@ %@¢)", statistics.min, minInfo.name, formatCents(minInfo.centsDifference)))
                    let maxInfo = closestPitchInfo(to: statistics.max)
                    Text(String(format: "Max: %.2f Hz (%@ %@¢)", statistics.max, maxInfo.name, formatCents(maxInfo.centsDifference)))
                    let avgInfo = closestPitchInfo(to: statistics.avg)
                    Text(String(format: "Avg: %.2f Hz (%@ %@¢)", statistics.avg, avgInfo.name, formatCents(avgInfo.centsDifference)))
                    let medianInfo = closestPitchInfo(to: statistics.median)
                    Text(String(format: "Median: %.2f Hz (%@ %@¢)", statistics.median, medianInfo.name, formatCents(medianInfo.centsDifference)))
                }
                Section("Variability Measures") {
                    Text(String(format: "Std Dev: %.2f Hz", statistics.stdDev))
                    Text(String(format: "IQR: %.2f Hz", statistics.iqr))
                    Text(String(format: "RMS: %.2f Hz", statistics.rms))
                }
                Section("Tuning Accuracy To Median") {
                    let pct = statistics.percentWithin(
                        target: values.median ?? 0,
                        toleranceCents: 5,
                        values: values)
                    Text(String(format: "Within ±5¢: %.1f%%", pct))
                }
            }
            .navigationTitle("Session Statistics")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Save the session before dismissing
                        let chakraTimeline = PitchChakraTimeline(pitches: values)
                        sessionStore.addSession(
                            duration: duration,
                            statistics: statistics,
                            values: values,
                            profileName: profileName,
                            chakraTimeline: chakraTimeline
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

// --- Helper Extension: Compute VoicePrintStats from a session ---
