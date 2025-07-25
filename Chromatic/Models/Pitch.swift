import Foundation

/// Representation of a musical pitch.
///
/// Marked `public` so that tests and previews outside the main target can
/// construct and reference `Pitch` values.
public struct Pitch: Identifiable, Hashable {
    public let id = UUID()
    let name: String
    let frequency: Double
}

/// All equal-tempered pitches from C0 through D#8/Eb8.
///
/// Declared `public` so that previews and unit tests can reference the same
/// canonical list of pitches instead of hard-coding their own copies.
public let pitchFrequencies: [Pitch] = [
    Pitch(name: "C0",   frequency: 16.35),
    Pitch(name: "C#0/Db0", frequency: 17.32),
    Pitch(name: "D0",   frequency: 18.35),
    Pitch(name: "D#0/Eb0", frequency: 19.45),
    Pitch(name: "E0",   frequency: 20.60),
    Pitch(name: "F0",   frequency: 21.83),
    Pitch(name: "F#0/Gb0", frequency: 23.12),
    Pitch(name: "G0",   frequency: 24.50),
    Pitch(name: "G#0/Ab0", frequency: 25.96),
    Pitch(name: "A0",   frequency: 27.50),
    Pitch(name: "A#0/Bb0", frequency: 29.14),
    Pitch(name: "B0",   frequency: 30.87),

    Pitch(name: "C1",   frequency: 32.70),
    Pitch(name: "C#1/Db1", frequency: 34.65),
    Pitch(name: "D1",   frequency: 36.71),
    Pitch(name: "D#1/Eb1", frequency: 38.89),
    Pitch(name: "E1",   frequency: 41.20),
    Pitch(name: "F1",   frequency: 43.65),
    Pitch(name: "F#1/Gb1", frequency: 46.25),
    Pitch(name: "G1",   frequency: 49.00),
    Pitch(name: "G#1/Ab1", frequency: 51.91),
    Pitch(name: "A1",   frequency: 55.00),
    Pitch(name: "A#1/Bb1", frequency: 58.27),
    Pitch(name: "B1",   frequency: 61.74),

    Pitch(name: "C2",   frequency: 65.41),
    Pitch(name: "C#2/Db2", frequency: 69.30),
    Pitch(name: "D2",   frequency: 73.42),
    Pitch(name: "D#2/Eb2", frequency: 77.78),
    Pitch(name: "E2",   frequency: 82.41),
    Pitch(name: "F2",   frequency: 87.31),
    Pitch(name: "F#2/Gb2", frequency: 92.50),
    Pitch(name: "G2",   frequency: 98.00),
    Pitch(name: "G#2/Ab2", frequency: 103.83),
    Pitch(name: "A2",   frequency: 110.00),
    Pitch(name: "A#2/Bb2", frequency: 116.54),
    Pitch(name: "B2",   frequency: 123.47),

    Pitch(name: "C3",   frequency: 130.81),
    Pitch(name: "C#3/Db3", frequency: 138.59),
    Pitch(name: "D3",   frequency: 146.83),
    Pitch(name: "D#3/Eb3", frequency: 155.56),
    Pitch(name: "E3",   frequency: 164.81),
    Pitch(name: "F3",   frequency: 174.61),
    Pitch(name: "F#3/Gb3", frequency: 185.00),
    Pitch(name: "G3",   frequency: 196.00),
    Pitch(name: "G#3/Ab3", frequency: 207.65),
    Pitch(name: "A3",   frequency: 220.00),
    Pitch(name: "A#3/Bb3", frequency: 233.08),
    Pitch(name: "B3",   frequency: 246.94),

    Pitch(name: "C4",   frequency: 261.63),
    Pitch(name: "C#4/Db4", frequency: 277.18),
    Pitch(name: "D4",   frequency: 293.66),
    Pitch(name: "D#4/Eb4", frequency: 311.13),
    Pitch(name: "E4",   frequency: 329.63),
    Pitch(name: "F4",   frequency: 349.23),
    Pitch(name: "F#4/Gb4", frequency: 369.99),
    Pitch(name: "G4",   frequency: 392.00),
    Pitch(name: "G#4/Ab4", frequency: 415.30),
    Pitch(name: "A4",   frequency: 440.00),
    Pitch(name: "A#4/Bb4", frequency: 466.16),
    Pitch(name: "B4",   frequency: 493.88),

    Pitch(name: "C5",   frequency: 523.25),
    Pitch(name: "C#5/Db5", frequency: 554.37),
    Pitch(name: "D5",   frequency: 587.33),
    Pitch(name: "D#5/Eb5", frequency: 622.25),
    Pitch(name: "E5",   frequency: 659.26),
    Pitch(name: "F5",   frequency: 698.46),
    Pitch(name: "F#5/Gb5", frequency: 739.99),
    Pitch(name: "G5",   frequency: 783.99),
    Pitch(name: "G#5/Ab5", frequency: 830.61),
    Pitch(name: "A5",   frequency: 880.00),
    Pitch(name: "A#5/Bb5", frequency: 932.33),
    Pitch(name: "B5",   frequency: 987.77),

    Pitch(name: "C6",   frequency: 1046.50),
    Pitch(name: "C#6/Db6", frequency: 1108.73),
    Pitch(name: "D6",   frequency: 1174.66),
    Pitch(name: "D#6/Eb6", frequency: 1244.51),
    Pitch(name: "E6",   frequency: 1318.51),
    Pitch(name: "F6",   frequency: 1396.91),
    Pitch(name: "F#6/Gb6", frequency: 1479.98),
    Pitch(name: "G6",   frequency: 1567.98),
    Pitch(name: "G#6/Ab6", frequency: 1661.22),
    Pitch(name: "A6",   frequency: 1760.00),
    Pitch(name: "A#6/Bb6", frequency: 1864.66),
    Pitch(name: "B6",   frequency: 1975.53),

    Pitch(name: "C7",   frequency: 2093.00),
    Pitch(name: "C#7/Db7", frequency: 2217.46),
    Pitch(name: "D7",   frequency: 2349.32),
    Pitch(name: "D#7/Eb7", frequency: 2489.02),
    Pitch(name: "E7",   frequency: 2637.02),
    Pitch(name: "F7",   frequency: 2793.83),
    Pitch(name: "F#7/Gb7", frequency: 2959.96),
    Pitch(name: "G7",   frequency: 3135.96),
    Pitch(name: "G#7/Ab7", frequency: 3322.44),
    Pitch(name: "A7",   frequency: 3520.00),
    Pitch(name: "A#7/Bb7", frequency: 3729.31),
    Pitch(name: "B7",   frequency: 3951.07),

    Pitch(name: "C8",   frequency: 4186.01),
    Pitch(name: "C#8/Db8", frequency: 4434.92),
    Pitch(name: "D8",   frequency: 4698.64),
    Pitch(name: "D#8/Eb8", frequency: 4978.03),
]
