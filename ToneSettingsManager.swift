import SwiftUI
import Combine

// Default HarmonicAmplitudes if not defined elsewhere globally
// If HarmonicAmplitudes is already defined in your project, this can be removed.
// For now, I'll assume it's defined in TonePlayerControlPanel.swift or accessible.
// If not, you'll need to ensure its definition is available here.
// For the purpose of this file, I'll include a basic definition if it's missing,
// but ideally, it should be in its own file or a shared model file.

/*
struct HarmonicAmplitudes: Equatable {
    var fundamental: Double = 0.75
    var harmonic2: Double = 0.1
    var harmonic3: Double = 0.05
    var formant: Double = 0.1
    var noise: Double = 0.01
    var formantFrequency: Double = 1000

    // Add other properties if they exist in your actual struct
}
*/

class ToneSettingsManager: ObservableObject {
    @Published var harmonicAmplitudes: HarmonicAmplitudes = HarmonicAmplitudes() // Default values

    static let shared = ToneSettingsManager()

    // Private init to ensure singleton usage if desired, though not strictly necessary
    // if you prefer manual instantiation in specific contexts.
    // For shared instance usage, this is good practice.
    private init() {}
}

// Ensure HarmonicAmplitudes struct is accessible.
// If it's in another file like `TonePlayer.swift` or `Models.swift`,
// make sure this file can see it.
// For example, if HarmonicAmplitudes is in TonePlayerControlPanel.swift,
// and that file is part of the same module, it should be fine.
// If it's not, you might need to move HarmonicAmplitudes to its own file
// or ensure it's publicly accessible.

// For the sake of this example, I am assuming HarmonicAmplitudes is defined
// in such a way that this file can access it. Typically, this means it's either
// in a shared models file, or defined in a file that's part of the target
// and not marked as private/fileprivate to its original file.
// The provided file `TonePlayerControlPanel.swift` has it.
// To ensure it's usable, it should not be private to that file.
// Let's assume it's defined at the top level in TonePlayerControlPanel.swift or similar.
