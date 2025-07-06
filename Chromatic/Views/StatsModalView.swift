import SwiftUI

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
