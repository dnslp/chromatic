
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
class Channel: Identifiable {
    let id = UUID()
    var waveform: Waveform = .sine
    var frequency: Double = 440.0    // Hz
    var selectedPitch: Pitch? = nil  // Add this line
    var gain: Float = 0.5            // 0.0–1.0
    var isPlaying: Bool = false      // Start/Stop flag
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
