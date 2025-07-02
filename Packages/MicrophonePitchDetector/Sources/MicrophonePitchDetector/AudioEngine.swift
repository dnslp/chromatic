// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation

extension AVAudioMixerNode {
    /// Make a connection without breaking other connections.
    func connectMixer(input: AVAudioNode) {
        guard let engine = engine else { return }

        var points = engine.outputConnectionPoints(for: input, outputBus: 0)
        if points.contains(where: { $0.node === self }) {
            return
        }

        points.append(AVAudioConnectionPoint(node: self, bus: nextAvailableInputBus))
        engine.connect(input, to: points, fromBus: 0, format: .stereo)
    }
}

/// AudioKit's wrapper for AVAudioEngine
public final class AudioEngine {
    /// Internal AVAudioEngine
    let avEngine: AVAudioEngine

    /// Input node mixer
    private final class Input: Mixer {
        var isNotConnected = true

        func connect(to engine: AudioEngine) {
            engine.avEngine.attach(auMixer)
            engine.avEngine.connect(engine.avEngine.inputNode, to: auMixer, format: nil)
        }
    }

    private let _input = Input()

    /// Input for microphone is created when this is accessed
    var inputMixer: AVAudioMixerNode {
        if _input.isNotConnected {
            _input.connect(to: self)
            _input.isNotConnected = false
            self.createSilentOutput()
        }
        return _input.auMixer
    }

    /// Initialize with an optional external AVAudioEngine
    public init(avAudioEngine: AVAudioEngine = AVAudioEngine()) {
        self.avEngine = avAudioEngine
    }

    /// Start the engine
    public func start() throws {
        try avEngine.start()
    }


    // MARK: - Private

    private func createSilentOutput() {
        let output = _input
        avEngine.attach(output.auMixer)

        // create the on demand mixer if needed
        createEngineMixer(input: output)
    }

    // simulate the AVAudioEngine.mainMixerNode, but create it ourselves to ensure the
    // correct sample rate is used from .stereo
    private func createEngineMixer(input: Mixer) {
        let mixer = Mixer()
        avEngine.attach(mixer.auMixer)
        avEngine.connect(mixer.auMixer, to: avEngine.mainMixerNode, format: .stereo)
        mixer.addInput(input)
    }
}

private extension AVAudioFormat {
    static var stereo: AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2) ??
            AVAudioFormat()
    }
}
