import Foundation

// SessionStatistics now holds both stats and duration
struct SessionStatistics {
    let pitch: PitchStatistics
    let duration: TimeInterval
}
