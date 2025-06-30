struct TunerData {
    let pitch: Frequency
    let closestNote: ScaleNote.Match
    let amplitude: Double // New property
}

extension TunerData {
    init(pitch: Double = 440, amplitude: Double = 0.0) { // Added amplitude to init
        self.pitch = Frequency(floatLiteral: pitch)
        self.closestNote = ScaleNote.closestNote(to: self.pitch)
        self.amplitude = amplitude // Store amplitude
    }
}
