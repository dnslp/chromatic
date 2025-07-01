
//FunctionGeneratorEngine.swift
// 4-channel audio function generator using AVAudioSourceNode

import Foundation
import AVFoundation
import Combine

/// Supported waveform types
enum Waveform: String, CaseIterable, Identifiable {
    case sine, square, sawtooth, triangle
    var id: String { rawValue }
}

/// Single oscillator channel
class Channel: ObservableObject, Identifiable { // Conforms to ObservableObject
    let id = UUID()
    @Published var waveform: Waveform = .sine
    @Published var frequency: Double = 440.0 { // Hz
        didSet {
            let newMatchedPitch = Channel.findPitch(for: frequency, in: pitchFrequencies, tolerance: 0.5)

            if let currentMatchedPitch = newMatchedPitch { // A pitch was found within tolerance
                if self.selectedPitch?.name != currentMatchedPitch.name { // Only update if different name
                    self.selectedPitch = currentMatchedPitch
                }
                // If names are the same, selectedPitch is not changed, preserving the instance if it was already correct.
            } else { // No pitch matched
                if self.selectedPitch != nil { // Only set to nil if it wasn't already nil
                    self.selectedPitch = nil
                }
            }
        }
    }

    // Helper function to find a pitch within tolerance
    private static func findPitch(for frequency: Double, in pitches: [Pitch], tolerance: Double) -> Pitch? {
        return pitches.first(where: { abs($0.frequency - frequency) < tolerance })
    }

    @Published var selectedPitch: Pitch? = nil {
        didSet {
            // Automatically update frequency when selectedPitch changes,
            // but only if the new pitch is different from the old one,
            // and its frequency is different from the current frequency.
            // This check `abs(newPitch.frequency - frequency) > 0.001` is important to prevent loops
            // if frequency's didSet also tries to update selectedPitch.
            if let newPitch = selectedPitch, oldValue?.name != newPitch.name, abs(newPitch.frequency - frequency) > 0.001 {
                self.frequency = newPitch.frequency
            }
        }
    }
    @Published var gain: Float = 0.5            // 0.0–1.0
    @Published var isPlaying: Bool = false      // Start/Stop flag
    fileprivate var phase: Double = 0.0 // Not @Published as it's internal to audio rendering
    var sourceNode: AVAudioSourceNode!  // initialized in init(), not UI state

    init(format: AVAudioFormat) {
        // Initialize selectedPitch and frequency with a default value, e.g., A4
        let defaultPitch = pitchFrequencies.first(where: { $0.name == "A4" }) ?? pitchFrequencies.first!
        self.selectedPitch = defaultPitch
        self.frequency = defaultPitch.frequency
        // Note: The didSet for selectedPitch will set frequency, so explicit frequency set here might be redundant
        // but it's fine as a clear initialization.

        sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sampleRate = format.sampleRate
            let phaseIncrement = self.frequency / sampleRate
            let twoPi = 2.0 * Double.pi

            for frame in 0..<Int(frameCount) {
                // generate raw waveform sample
                let raw: Float
                let ph = self.phase
                switch self.waveform {
                case .sine:
                    raw = Float(sin(twoPi * ph))
                case .square:
                    raw = ph < 0.5 ? 1.0 : -1.0
                case .sawtooth:
                    raw = Float(2.0 * (ph - 0.5))
                case .triangle:
                    raw = Float(1.0 - 4.0 * abs(ph - 0.5))
                }
                // apply gain and start/stop
                let enabled: Float = self.isPlaying ? 1.0 : 0.0
                let sample = raw * self.gain * enabled

                // write to buffers (mono)
                for buffer in abl {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = sample
                }

                // advance phase
                self.phase += phaseIncrement
                if self.phase >= 1.0 { self.phase -= 1.0 }
            }
            return noErr
        }
    }
}

/// Engine managing four oscillators
class FunctionGeneratorEngine: ObservableObject {
    @Published var channels: [Channel] = []
    private let engine = AVAudioEngine()

    init(channelsCount: Int = 4) {
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        for _ in 0..<channelsCount {
            let channel = Channel(format: format)
            channels.append(channel)
            engine.attach(channel.sourceNode)
            engine.connect(channel.sourceNode, to: engine.mainMixerNode, format: format)
        }

        do {
            try engine.start()
        } catch {
            print("❌ Audio engine failed to start: \(error)")
        }
    }

    func setWaveform(_ wf: Waveform, for index: Int) {
        guard channels.indices.contains(index) else { return }
        channels[index].waveform = wf
    }

    func setFrequency(_ freq: Double, for index: Int) {
        guard channels.indices.contains(index) else { return }
        channels[index].frequency = freq
    }

    func setGain(_ gain: Float, for index: Int) {
        guard channels.indices.contains(index) else { return }
        channels[index].gain = gain
    }
}
