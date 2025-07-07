//
//  TonePlayer.swift
//  Chromatic
//
//  Created by David Nyman on 7/7/25.
//

import Foundation
import AVFoundation

struct HarmonicAmplitudes {
    var fundamental: Double = 1.0
    var harmonic2: Double = 0.10
    var harmonic3: Double = 0.05
    var formant: Double = 0.05
}

class TonePlayer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isConfigured = false

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

    func play(frequency: Double, duration: Double = 1.2, amplitudes: HarmonicAmplitudes = HarmonicAmplitudes()) {
        stop()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let attackTime: Double = 0.04
        let releaseTime: Double = 0.12

        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate

            let fund = amplitudes.fundamental * sin(2 * .pi * frequency * t)
            let harm2 = amplitudes.harmonic2 * sin(2 * .pi * frequency * 2 * t)
            let harm3 = amplitudes.harmonic3 * sin(2 * .pi * frequency * 3 * t)
            let formant = amplitudes.formant * sin(2 * .pi * 1200 * t)

            var sample = fund + harm2 + harm3

            var env: Double = 1.0
            if t < attackTime {
                env = t / attackTime
            } else if t > duration - releaseTime {
                env = max(0, (duration - t) / releaseTime)
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

