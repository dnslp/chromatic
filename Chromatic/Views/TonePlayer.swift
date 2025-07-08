import Foundation
import AVFoundation

// Define enums for WaveformType and NoiseType
enum WaveformType: String, Codable, CaseIterable, Identifiable {
    case sine, square, triangle, sawtooth
    var id: String { self.rawValue }
    var displayName: String { self.rawValue.capitalized }
}

enum NoiseType: String, Codable, CaseIterable, Identifiable {
    case white, pink, brown
    var id: String { self.rawValue }
    var displayName: String { self.rawValue.capitalized }
}

struct HarmonicAmplitudes: Codable, Equatable {
    var fundamental: Double = 1.0
    var harmonic2: Double = 0.10
    var harmonic3: Double = 0.05
    var formant: Double = 0.05
    var noiseLevel: Double = 0.00 // Renamed from noise
    var formantFrequency: Double = 1000 // new default, adjustable

    // New properties
    var waveform: WaveformType = .sine
    var noiseType: NoiseType = .white
    var eqLowGain: Double = 0.0 // Gain in dB (-96dB to +24dB for AVAudioUnitEQ)
    var eqMidGain: Double = 0.0
    var eqHighGain: Double = 0.0

    // Default initializer will use the defaults specified above.
    // If a specific default set is needed for when JSON decoding fails,
    // ToneSettingsManager can create an instance with specific defaults.
}

// --- ToneSettingsManager is in a separate file: Chromatic/Models/ToneSettingsManager.swift ---

// Helper class for generating Pink Noise (1/f noise)
// Using the Voss-McCartney algorithm (simplified)
fileprivate class PinkNoiseGenerator {
    private var b0: Double = 0.0
    private var b1: Double = 0.0
    private var b2: Double = 0.0
    private var b3: Double = 0.0
    private var b4: Double = 0.0
    private var b5: Double = 0.0
    private var b6: Double = 0.0 // Seven white noise generators

    func next() -> Double {
        let white = Double.random(in: -1.0...1.0)
        
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        
        let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926 // Update b6 last
        
        return pink / 5.0 // Scaling factor to keep it roughly in -1 to 1 range
    }

    func reset() {
        b0 = 0; b1 = 0; b2 = 0; b3 = 0; b4 = 0; b5 = 0; b6 = 0
    }
}

// Helper class for generating Brown Noise (1/f^2 noise, Brownian motion)
fileprivate class BrownNoiseGenerator {
    private var lastOutput: Double = 0.0
    private let step: Double = 0.1 // Controls how fast the noise value changes

    func next() -> Double {
        let white = Double.random(in: -1.0...1.0)
        lastOutput += white * step
        // Clamp to prevent runaway values, keep it roughly in -1 to 1
        if lastOutput < -1.0 { lastOutput = -1.0 }
        if lastOutput > 1.0 { lastOutput = 1.0 }
        return lastOutput
    }

    func reset() {
        lastOutput = 0.0
    }
}

class TonePlayer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 3) // 3-band EQ
    private var isConfigured = false
    var settings: ToneSettingsManager = .shared

    // For Pink/Brown noise generation (simple state)
    private var pinkNoise = PinkNoiseGenerator()
    private var brownNoise = BrownNoiseGenerator()

    init() {
        setupEngine()
    }

    private func setupEngine() {
        guard !isConfigured else { return }
        audioEngine.attach(player)
        audioEngine.attach(eqNode)

        // Define standard EQ band frequencies
        // These are typical values, can be adjusted.
        eqNode.bands[0].filterType = .parametric
        eqNode.bands[0].frequency = 120.0  // Low shelf typically, but parametric gives more control
        eqNode.bands[0].bandwidth = 1.0 // Broad Q
        eqNode.bands[0].bypass = false

        eqNode.bands[1].filterType = .parametric
        eqNode.bands[1].frequency = 1000.0 // Mid
        eqNode.bands[1].bandwidth = 1.0  // Broad Q
        eqNode.bands[1].bypass = false

        eqNode.bands[2].filterType = .parametric
        eqNode.bands[2].frequency = 8000.0 // High shelf typically
        eqNode.bands[2].bandwidth = 1.0 // Broad Q
        eqNode.bands[2].bypass = false
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioEngine.connect(player, to: eqNode, format: format)
        audioEngine.connect(eqNode, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
        isConfigured = true
    }

    private func updateEQParameters(lowGain: Double, midGain: Double, highGain: Double) {
        eqNode.bands[0].gain = Float(lowGain)
        eqNode.bands[1].gain = Float(midGain)
        eqNode.bands[2].gain = Float(highGain)
    }

    // MARK: - Waveform Generators
    private func generateSine(phase: Double) -> Double {
        return sin(phase)
    }

    private func generateSquare(phase: Double) -> Double {
        return sin(phase) >= 0 ? 1.0 : -1.0
    }

    private func generateTriangle(phase: Double) -> Double {
        // Triangle wave: 2.0 / .pi * asin(sin(phase))
        // Or simpler: normalize ((phase / (2 * .pi)).truncatingRemainder(dividingBy: 1.0) * 2.0 - 1.0)
        // For a cycle from 0 to 2*PI:
        let normalizedPhase = (phase / (2.0 * .pi)).truncatingRemainder(dividingBy: 1.0)
        if normalizedPhase < 0.25 {
            return normalizedPhase * 4.0
        } else if normalizedPhase < 0.75 {
            return 2.0 - (normalizedPhase * 4.0)
        } else {
            return (normalizedPhase * 4.0) - 4.0
        }
    }

    private func generateSawtooth(phase: Double) -> Double {
        // Sawtooth wave: (phase / .pi).truncatingRemainder(dividingBy: 2.0) - 1.0
        // For a cycle from 0 to 2*PI:
        let normalizedPhase = (phase / (2.0 * .pi)).truncatingRemainder(dividingBy: 1.0)
        return (normalizedPhase * 2.0) - 1.0
    }

    private func getWaveformValue(waveformType: WaveformType, phase: Double) -> Double {
        switch waveformType {
        case .sine:
            return generateSine(phase: phase)
        case .square:
            return generateSquare(phase: phase)
        case .triangle:
            return generateTriangle(phase: phase)
        case .sawtooth:
            return generateSawtooth(phase: phase)
        }
    }
    
    // MARK: - Noise Generators
    private func generateNoise(type: NoiseType, level: Double) -> Double {
        guard level > 0 else { return 0.0 }
        var noiseSample: Double = 0.0
        switch type {
        case .white:
            noiseSample = Double.random(in: -1.0...1.0)
        case .pink:
            noiseSample = pinkNoise.next()
        case .brown:
            noiseSample = brownNoise.next()
        }
        return noiseSample * level
    }


    /// Always use global settings unless explicitly overridden
    func play(
        frequency: Double,
        duration: Double? = nil,
        amplitudes: HarmonicAmplitudes? = nil,
        attack: Double? = nil,
        release: Double? = nil
    ) {
        stop() // Stop any existing playback
        player.reset() // Resets any internal state of the player node

        let amps = amplitudes ?? settings.amplitudes
        let atk = attack ?? settings.attack
        let rel = release ?? settings.release
        let dur = duration ?? 1.2

        // Update EQ settings before generating buffer
        updateEQParameters(lowGain: amps.eqLowGain, midGain: amps.eqMidGain, highGain: amps.eqHighGain)

        let sampleRate = audioEngine.outputNode.inputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(format.sampleRate * dur)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Failed to create buffer")
            return
        }
        buffer.frameLength = frameCount

        // Reset noise generators for consistent sound start
        pinkNoise.reset()
        brownNoise.reset()

        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate // time in seconds

            // Calculate phase for each component
            let fundamentalPhase = 2 * .pi * frequency * t
            let harmonic2Phase = 2 * .pi * frequency * 2 * t
            let harmonic3Phase = 2 * .pi * frequency * 3 * t
            let formantPhase = 2 * .pi * amps.formantFrequency * t

            let fund = amps.fundamental * getWaveformValue(waveformType: amps.waveform, phase: fundamentalPhase)
            let harm2 = amps.harmonic2 * getWaveformValue(waveformType: amps.waveform, phase: harmonic2Phase) // Using same waveform for harmonics
            let harm3 = amps.harmonic3 * getWaveformValue(waveformType: amps.waveform, phase: harmonic3Phase) // Using same waveform for harmonics
            
            // Formant is typically a sine wave (resonant peak)
            let formantVal = (amps.formant * 0.20) * sin(formantPhase) // scaled down
            
            let noiseVal = generateNoise(type: amps.noiseType, level: amps.noiseLevel)

            var sample = fund + harm2 + harm3 + formantVal + noiseVal

            // Envelope
            var env: Double = 1.0
            if t < atk { env = t / atk }
            else if t > dur - rel { env = max(0, (dur - t) / rel) }
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
