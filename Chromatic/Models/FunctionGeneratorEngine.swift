
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
    @Published var frequency: Double = 440.0    // Hz
    @Published var selectedPitch: Pitch? = nil
    @Published var gain: Float = 0.5            // 0.0–1.0
    @Published var isPlaying: Bool = false      // Start/Stop flag

    // phase should not be @Published as it changes rapidly and is an internal rendering detail.
    fileprivate var phase: Double = 0.0
    var sourceNode: AVAudioSourceNode!  // initialized in init()

    init(format: AVAudioFormat) {
        // Initialize selectedPitch with a default value if needed, e.g., A4
        if let defaultPitch = pitchFrequencies.first(where: { $0.name == "A4" }) {
            self.selectedPitch = defaultPitch
            self.frequency = defaultPitch.frequency
        }

        sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sampleRate = format.sampleRate
            // Read self.frequency within the audio rendering block to ensure it uses the latest value.
            // No need to capture it separately if it's @Published and updated on the main thread.
            let currentFrequency = self.frequency
            let phaseIncrement = currentFrequency / sampleRate
            let twoPi = 2.0 * Double.pi

            for frame in 0..<Int(frameCount) {
                // generate raw waveform sample
                let raw: Float
                let ph = self.phase
                switch self.waveform { // Read self.waveform
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
                let currentGain = self.gain // Read self.gain
                let currentIsPlaying = self.isPlaying // Read self.isPlaying
                let enabled: Float = currentIsPlaying ? 1.0 : 0.0
                let sample = raw * currentGain * enabled

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
            let channel = Channel(format: format) // Channel is now an ObservableObject
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

    // The setters in FunctionGeneratorEngine will now trigger @Published updates
    // on the Channel objects themselves if their properties change,
    // which SwiftUI views observing those Channel objects will pick up.

    func setWaveform(_ wf: Waveform, for index: Int) {
        guard channels.indices.contains(index) else { return }
        channels[index].waveform = wf // This assignment now publishes changes from Channel
    }

    func setFrequency(_ freq: Double, for index: Int) {
        guard channels.indices.contains(index) else { return }
        channels[index].frequency = freq // This assignment now publishes changes from Channel
    }

    func setGain(_ gain: Float, for index: Int) {
        guard channels.indices.contains(index) else { return }
        channels[index].gain = gain // This assignment now publishes changes from Channel
    }
}
