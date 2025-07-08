import Foundation

struct TunerData {
    let pitch: Frequency
    let closestNote: ScaleNote.Match
    let amplitude: Double

    var harmonics: [Double] = []  // Add this line!

    var isRecording: Bool = false
    var recordedPitches: [Double] = []
    var isTunerActive: Bool = true // Added for managing pause/resume state

    init(
           pitch: Double = 440,
           amplitude: Double = 0.0,
           harmonics: [Double]? = nil  // Optional!
       ) {
           self.pitch = Frequency(floatLiteral: pitch)
           self.closestNote = ScaleNote.closestNote(to: self.pitch)
           self.amplitude = amplitude
           // Default: f₁ through f₇
           self.harmonics = harmonics ?? (1...7).map { Double($0) * pitch }
       }

    mutating func startRecording() {
        isRecording = true
        recordedPitches.removeAll()
    }

    mutating func stopRecording() {
        isRecording = false
    }

    mutating func addPitch(_ pitch: Double) {
        if isRecording {
            recordedPitches.append(pitch)
        }
    }

    mutating func clearRecording() {
        recordedPitches.removeAll()
    }

    func calculateStatistics() -> (min: Double, max: Double, avg: Double)? {
        guard !recordedPitches.isEmpty else { return nil }

        let minPitch = recordedPitches.min() ?? 0.0
        let maxPitch = recordedPitches.max() ?? 0.0
        let avgPitch = recordedPitches.reduce(0.0, +) / Double(recordedPitches.count)

        return (minPitch, maxPitch, avgPitch)
    }
}
