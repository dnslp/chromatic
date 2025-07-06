import SwiftUI

// MARK: - Stats Modal View
struct StatsModalView: View {
    let statistics: PitchStatistics
    let duration: TimeInterval
    let values: [Double]
    @Environment(\.dismiss) private var dismiss

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
                Section("Session Info") {
                    let safeDuration = max(0, duration)
                    Text("Duration: \(formatTime(safeDuration))")
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
