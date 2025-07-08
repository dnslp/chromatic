import Foundation

struct TunerData {
    let pitch: Frequency
    let closestNote: ScaleNote.Match
    let amplitude: Double

    var harmonics: [Double] = []  // Add this line!

    var isRecording: Bool = false
    var recordedPitches: [Double] = []

    init(
        pitch: Double = 440,
        amplitude: Double = 0.0,
        harmonics: [Double] = []
    ) {
        self.pitch = Frequency(floatLiteral: pitch)
        self.closestNote = ScaleNote.closestNote(to: self.pitch)
        self.amplitude = amplitude
        self.harmonics = harmonics   // And this!
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
