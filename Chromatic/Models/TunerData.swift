struct TunerData {
    let pitch: Frequency
    let closestNote: ScaleNote.Match
    let amplitude: Double // New property
    var playlistManager: PlaylistManager? = nil // Optional PlaylistManager
}

extension TunerData {
    init(pitch: Double = 440, amplitude: Double = 0.0, playlistManager: PlaylistManager? = nil) { // Added amplitude and playlistManager to init
        self.pitch = Frequency(floatLiteral: pitch)
        self.closestNote = ScaleNote.closestNote(to: self.pitch)
        self.amplitude = amplitude // Store amplitude
        self.playlistManager = playlistManager
    }
}
