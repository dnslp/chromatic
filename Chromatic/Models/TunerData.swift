struct TunerData {
    let pitch: Frequency
    let closestNote: ScaleNote.Match
    let amplitude: Double // New property
    let durationInPitchThreshold: Double // New property
}

extension TunerData {
    init(pitch: Double = 440, amplitude: Double = 0.0, durationInPitchThreshold: Double = 0.0) { // Added durationInPitchThreshold to init
        self.pitch = Frequency(floatLiteral: pitch)
        self.closestNote = ScaleNote.closestNote(to: self.pitch)
        self.amplitude = amplitude // Store amplitude
        self.durationInPitchThreshold = durationInPitchThreshold // Store durationInPitchThreshold
    }
}
