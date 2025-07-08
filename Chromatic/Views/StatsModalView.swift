import SwiftUI

// MARK: - Stats Modal View
struct StatsModalView: View {
    @EnvironmentObject var sessionStore: SessionStore
    let statistics: PitchStatistics
    let duration: TimeInterval
    let values: [Double]
    let profileName: String // Added profileName property
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

// Preview for StatsModalView
struct StatsModalView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
            .environmentObject(SessionStore()) // Provide SessionStore for the preview
    }

    struct PreviewWrapper: View {
        @State private var showModal = true

        // Create sample data for the preview
        let sampleStats = PitchStatistics(
            min: 110.0, // A2
            max: 440.0, // A4
            avg: 220.0, // A3
            median: 200.0,
            stdDev: 50.0,
            iqr: 80.0,
            rms: 230.0
        )
        let sampleDuration: TimeInterval = 125 // 2 minutes 5 seconds
        let sampleValues: [Double] = (0..<50).map { _ in Double.random(in: 100.0...500.0) }
        let sampleProfileName = "Guitar Standard"

        var body: some View {
            VStack {
                Text("This view presents the StatsModalView.")
                Button("Show Stats Modal") {
                    showModal = true
                }
            }
            .sheet(isPresented: $showModal) {
                StatsModalView(
                    statistics: sampleStats,
                    duration: sampleDuration,
                    values: sampleValues,
                    profileName: sampleProfileName
                )
            }
        }
    }
}

// Ensure pitchFrequencies is available for the preview context if it's defined globally or accessible.
// If it's part of a class or struct, it might need to be mocked or provided.
// For simplicity, assuming it's accessible or this part of preview won't crash.
// If `pitchFrequencies` is not globally available, you might need to define a sample one here:
//let pitchFrequencies: [(name: String, frequency: Double)] = [
//    ("A2", 110.00), ("A#2/Bb2", 116.54), ("B2", 123.47),
//    ("C3", 130.81), ("C#3/Db3", 138.59), ("D3", 146.83),
//    ("D#3/Eb3", 155.56), ("E3", 164.81), ("F3", 174.61),
//    ("F#3/Gb3", 185.00), ("G3", 196.00), ("G#3/Ab3", 207.65),
//    ("A3", 220.00), ("A#3/Bb3", 233.08), ("B3", 246.94),
//    ("C4", 261.63), ("C#4/Db4", 277.18), ("D4", 293.66),
//    ("D#4/Eb4", 311.13), ("E4", 329.63), ("F4", 349.23),
//    ("F#4/Gb4", 369.99), ("G4", 392.00), ("G#4/Ab4", 415.30),
//    ("A4", 440.00)
//]
