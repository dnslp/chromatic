import Foundation

// MARK: - Extended Pitch Statistics Models & Helpers
/// Encapsulates descriptive statistics for a recording session's pitch data
struct PitchStatistics: Codable { // Add Codable conformance
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
