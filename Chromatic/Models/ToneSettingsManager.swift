import Foundation
// HarmonicAmplitudes, WaveformType, and NoiseType are now defined in TonePlayer.swift
// and should be accessible globally if that file is part of the same module/target.

class ToneSettingsManager: ObservableObject {
    static let shared = ToneSettingsManager()
    @Published var amplitudes: HarmonicAmplitudes {
        didSet { save() }
    }
    @Published var attack: Double {
        didSet { save() }
    }
    @Published var release: Double {
        didSet { save() }
    }

    // Changed key to avoid conflicts with old versions lacking new fields.
    private let amplitudesKey = "tonePlayerAmplitudes_v2"
    private let attackKey = "tonePlayerAttack"
    private let releaseKey = "tonePlayerRelease"

    private init() {
        if let data = UserDefaults.standard.data(forKey: amplitudesKey),
           let loadedAmplitudes = try? JSONDecoder().decode(HarmonicAmplitudes.self, from: data) {
            amplitudes = loadedAmplitudes
        } else {
            // Initialize with default values from HarmonicAmplitudes struct definition
            // The HarmonicAmplitudes struct now includes defaults for all new properties.
            amplitudes = HarmonicAmplitudes()
        }
        
        let savedAttack = UserDefaults.standard.object(forKey: attackKey) as? Double
        attack = savedAttack ?? 0.04 // Default attack
        
        let savedRelease = UserDefaults.standard.object(forKey: releaseKey) as? Double
        release = savedRelease ?? 0.12 // Default release
    }

    private func save() {
        if let data = try? JSONEncoder().encode(amplitudes) {
            UserDefaults.standard.set(data, forKey: amplitudesKey)
        }
        UserDefaults.standard.set(attack, forKey: attackKey)
        UserDefaults.standard.set(release, forKey: releaseKey)
    }
}
