//
//  TonePlayer.swift
//  Chromatic
//
//  Created by David Nyman on 7/7/25.
//

import Foundation
import AVFoundation

struct HarmonicAmplitudes: Codable, Equatable {
    var fundamental: Double = 1.0
    var harmonic2: Double = 0.10
    var harmonic3: Double = 0.05
    var formant: Double = 0.05
    var noise: Double = 0.00
}

// You likely have this already, but this is for reference:
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

    private let amplitudesKey = "tonePlayerAmplitudes"
    private let attackKey = "tonePlayerAttack"
    private let releaseKey = "tonePlayerRelease"

    private init() {
        if let data = UserDefaults.standard.data(forKey: amplitudesKey),
           let loaded = try? JSONDecoder().decode(HarmonicAmplitudes.self, from: data) {
            amplitudes = loaded
        } else {
            amplitudes = HarmonicAmplitudes()
        }
        let savedAttack = UserDefaults.standard.object(forKey: attackKey) as? Double
        attack = savedAttack ?? 0.04
        let savedRelease = UserDefaults.standard.object(forKey: releaseKey) as? Double
        release = savedRelease ?? 0.12
    }

    private func save() {
        if let data = try? JSONEncoder().encode(amplitudes) {
            UserDefaults.standard.set(data, forKey: amplitudesKey)
        }
        UserDefaults.standard.set(attack, forKey: attackKey)
        UserDefaults.standard.set(release, forKey: releaseKey)
    }
}

class TonePlayer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isConfigured = false

    // Optionally, allow overriding the settings manager (for testing)
    var settings: ToneSettingsManager = .shared

    init() {
        setupEngine()
    }

    private func setupEngine() {
        guard !isConfigured else { return }
        audioEngine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        try? audioEngine.start()
        isConfigured = true
    }

    /// Play a tone using the **current settings** (or pass a different amplitudes struct)
    func play(
        frequency: Double,
        duration: Double = 1.2,
        amplitudes: HarmonicAmplitudes? = nil,
        attack: Double? = nil,
        release: Double? = nil
    ) {
        stop()

        let amps = amplitudes ?? settings.amplitudes
        let atk = attack ?? settings.attack
        let rel = release ?? settings.release

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate

            let fund = amps.fundamental * sin(2 * .pi * frequency * t)
            let harm2 = amps.harmonic2 * sin(2 * .pi * frequency * 2 * t)
            let harm3 = amps.harmonic3 * sin(2 * .pi * frequency * 3 * t)
            let formant = amps.formant * sin(2 * .pi * 1200 * t)

            // Simple white noise for noise component
            let noise: Double = amps.noise > 0
                ? amps.noise * (Double.random(in: -1.0...1.0))
                : 0

            var sample = fund + harm2 + harm3 + formant + noise

            // Envelope
            var env: Double = 1.0
            if t < atk {
                env = t / atk
            } else if t > duration - rel {
                env = max(0, (duration - t) / rel)
            }
            sample *= env
            buffer.floatChannelData![0][i] = Float(sample * 0.27)
        }

        player.scheduleBuffer(buffer, at: nil, options: []) { }
        if !player.isPlaying {
            player.play()
        }
    }

    func stop() {
        if player.isPlaying {
            player.stop()
        }
    }
}
