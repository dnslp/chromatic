import Foundation

struct Pitch: Identifiable, Hashable {
    let id = UUID()
    let frequency: Double
    let octave: Int

    /// The base name of the note (e.g., C, D, E, F, G, A, B).
    let noteLetter: String

    /// The accidental, if any (e.g., "#", "b").
    let accidental: String?

    /// Provides the sharp representation of the note name, e.g., "C#3".
    var sharpNameWithOctave: String {
        let base = noteLetter
        if let acc = accidental, acc == "b" { // Convert flat to equivalent sharp
            // This is a simplified conversion. A more robust solution would use a map.
            // For example, Db -> C#, Eb -> D#, Gb -> F#, Ab -> G#, Bb -> A#
            // And handle wraparounds like Cb -> B or E# -> F
            switch base {
            case "D": return "C#" + "\(octave)"
            case "E": return "D#" + "\(octave)"
            case "G": return "F#" + "\(octave)"
            case "A": return "G#" + "\(octave)"
            case "B": return "A#" + "\(octave)"
            default: break // Should not happen for standard flats
            }
        }
        return base + (accidental ?? "") + "\(octave)"
    }

    /// Provides the flat representation of the note name, e.g., "Db3".
    var flatNameWithOctave: String {
        let base = noteLetter
        if let acc = accidental, acc == "#" { // Convert sharp to equivalent flat
            // Simplified conversion
            switch base {
            case "C": return "Db" + "\(octave)"
            case "D": return "Eb" + "\(octave)"
            case "F": return "Gb" + "\(octave)"
            case "G": return "Ab" + "\(octave)"
            case "A": return "Bb" + "\(octave)"
            default: break // Should not happen for standard sharps
            }
        }
        return base + (accidental ?? "") + "\(octave)"
    }

    /// Provides a display name based on a preference, defaulting to sharp.
    /// The `modifierPreference` would ideally be passed in or accessed from an environment.
    func displayName(preference: ModifierPreference = .preferSharps) -> String {
        if accidental == nil {
            return noteLetter + "\(octave)"
        }
        return preference == .preferSharps ? sharpNameWithOctave : flatNameWithOctave
    }

    init(frequency: Double, noteLetter: String, accidental: String? = nil, octave: Int) {
        self.frequency = frequency
        self.noteLetter = noteLetter
        self.accidental = accidental
        self.octave = octave
    }
}

/// Generates all equal-tempered pitches within a specified range.
func generatePitches(fromNoteIndex startNoteIndex: Int = 0, // MIDI note number for C0
                     toNoteIndex endNoteIndex: Int = 100,   // Approx D#8
                     referenceA4Frequency: Double = 440.0) -> [Pitch] {

    let noteNamesSharp = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    // For determining note letter and accidental from a single array based on preference later if needed
    // let noteNamesFlat = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

    var pitches: [Pitch] = []

    // MIDI note number for A4 is 69. C0 is typically MIDI note 12, but can vary.
    // We'll calculate relative to A4 (MIDI note 69).
    // Let's define C0 as MIDI note 12 for this calculation.
    // The startNoteIndex and endNoteIndex will be MIDI note numbers.
    // Standard piano range is A0 (21) to C8 (108).
    // C0 = MIDI 12, D#8 = MIDI 100 (as per original list's end)

    let midiNoteForC0 = 12 // Standard MIDI mapping for C0

    for midiNoteNumber in startNoteIndex...endNoteIndex {
        let frequency = referenceA4Frequency * pow(2.0, (Double(midiNoteNumber) - 69.0) / 12.0)

        let noteIndexInOctave = (midiNoteNumber - midiNoteForC0) % 12
        let octaveNumber = (midiNoteNumber - midiNoteForC0) / 12

        let nameComponents = noteNamesSharp[noteIndexInOctave]
        let noteLetter: String
        let accidental: String?

        if nameComponents.count > 1 { // Has an accidental
            noteLetter = String(nameComponents.first!)
            accidental = String(nameComponents.last!) // Will be "#"
        } else { // Natural note
            noteLetter = nameComponents
            accidental = nil
        }

        // Adjust octave for standard notation (C0, C1, etc.)
        // Our calculation makes C as the start of an octave.
        // MIDI note 12 is C0, 24 is C1 etc.
        // The octaveNumber derived above is correct if C0 is octave 0.

        pitches.append(Pitch(frequency: frequency,
                               noteLetter: noteLetter,
                               accidental: accidental,
                               octave: octaveNumber))
    }

    return pitches
}

/// All equal-tempered pitches, now generated programmatically.
/// Spans from C0 (MIDI 12) to D#8 (MIDI 100, which is Eb8, one semitone below E8).
/// The original list went up to D#8/Eb8. MIDI 100 is D#8/Eb8.
let pitchFrequencies: [Pitch] = generatePitches(fromNoteIndex: 12, toNoteIndex: 100)

// Example usage:
// let a4 = pitchFrequencies.first(where: { $0.sharpNameWithOctave == "A4" })
// print(a4?.frequency ?? "Not found")
// let cSharp5 = pitchFrequencies.first(where: { $0.displayName(preference: .preferSharps) == "C#5" })
// print(cSharp5?.frequency ?? "Not found", cSharp5?.flatNameWithOctave ?? "")
// let dFlat5 = pitchFrequencies.first(where: { $0.displayName(preference: .preferFlats) == "Db5" })
// print(dFlat5?.frequency ?? "Not found", dFlat5?.sharpNameWithOctave ?? "")
