import Foundation

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
