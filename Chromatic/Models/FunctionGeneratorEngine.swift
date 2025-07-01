
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

    // Helper function to find a pitch within tolerance (used for snapping)
    private static func findPitch(for frequency: Double, in pitches: [Pitch], tolerance: Double) -> Pitch? {
        return pitches.first(where: { abs($0.frequency - frequency) < tolerance })
    }

    // Helper function to find the absolute closest pitch (used for cents calculation)
    private static func findAbsoluteClosestPitch(to frequency: Double, in pitches: [Pitch]) -> Pitch? {
        guard !pitches.isEmpty else { return nil }

        var closestPitch = pitches[0]
        var smallestDifference = abs(pitches[0].frequency - frequency)

        for i in 1..<pitches.count {
            let difference = abs(pitches[i].frequency - frequency)
            if difference < smallestDifference {
                smallestDifference = difference
                closestPitch = pitches[i]
            }
        }
        return closestPitch
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
    @Published var isPlaying: Bool = false {     // Start/Stop flag
        didSet {
            if !isPlaying {
                // Reset power when channel stops explicitly
                // The tap might also do this, but this ensures immediate UI update if user stops it.
                DispatchQueue.main.async { // Ensure UI updates on main thread
                    self.averagePower = -160.0
                }
            }
        }
    }
    @Published var averagePower: Float = -160.0 // For VU meter, dBFS

    fileprivate var phase: Double = 0.0 // Not @Published as it's internal to audio rendering
    var sourceNode: AVAudioSourceNode!  // initialized in init(), not UI state
    private var isPlayingCancellable: AnyCancellable?


    var currentDisplayPitchName: String { // This was added in a previous step, ensure it's correctly placed
        selectedPitch?.name ?? (pitchFrequencies.first(where: { $0.name == "A4" })?.name ?? pitchFrequencies.first?.name ?? "N/A")
    }

    var closestPitchAndDeviation: (closestPitch: Pitch, deviationInCents: Double)? {
        guard let closestPitchFound = Channel.findAbsoluteClosestPitch(to: self.frequency, in: pitchFrequencies) else {
            return nil // Should not happen if pitchFrequencies is not empty
        }

        // Prevent division by zero or log of non-positive number.
        // Pitch frequencies should always be positive.
        guard closestPitchFound.frequency > 0 && self.frequency > 0 else {
            // If frequencies are identical (e.g. both zero, though invalid), cents is 0.
            if self.frequency == closestPitchFound.frequency {
                 return (closestPitch: closestPitchFound, deviationInCents: 0.0)
            }
            // Otherwise, cannot calculate cents for non-positive frequencies.
            return nil
        }

        let cents = 1200.0 * Darwin.log2(self.frequency / closestPitchFound.frequency)
        return (closestPitch: closestPitchFound, deviationInCents: cents)
    }

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
    @Published var isAnyChannelPlaying: Bool = false
    private let engine = AVAudioEngine()
    private var channelCancellables: [AnyCancellable] = []

    init(channelsCount: Int = 4) {
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate
        // Use a common format for all nodes and taps.
        // The sourceNode is mono, so we'll tap that mono signal.
        guard let processingFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            print("❌ Failed to create processing format for FunctionGeneratorEngine.")
            // Consider throwing an error or handling this more gracefully
            return
        }

        for i in 0..<channelsCount {
            let channel = Channel(format: processingFormat)
            channels.append(channel)
            engine.attach(channel.sourceNode)
            engine.connect(channel.sourceNode, to: engine.mainMixerNode, format: processingFormat)

            // Subscribe to isPlaying for this channel
            let cancellable = channel.$isPlaying.sink { [weak self] _ in
                self?.updateOverallPlayingStatus()
            }
            channelCancellables.append(cancellable)

            // Install tap on the sourceNode's output
            // Bus 0 is typically the output bus for a source node.
            channel.sourceNode.installTap(onBus: 0, bufferSize: 1024, format: processingFormat) { [weak channel] (buffer, time) in
                guard let strongChannel = channel, strongChannel.isPlaying else {
                    // If channel is not playing, ensure its power is set to minimum
                    // This might be redundant if isPlaying.didSet handles it, but good for safety from tap perspective.
                    if strongChannel?.averagePower != -160.0 {
                         DispatchQueue.main.async { strongChannel?.averagePower = -160.0 }
                    }
                    return
                }

                let frameLength = Int(buffer.frameLength)
                guard let floatData = buffer.floatChannelData?[0] else { return }

                var sumOfSquares: Float = 0.0
                for i in 0..<frameLength {
                    sumOfSquares += floatData[i] * floatData[i]
                }
                let rms = sqrt(sumOfSquares / Float(frameLength))

                var dbPower: Float
                if rms > 0.0 {
                    dbPower = 20 * log10(rms)
                } else {
                    dbPower = -160.0 // Or some other floor value for silence
                }

                // Ensure gain is factored in, as tap is on sourceNode before mixer connections might apply gain.
                // However, our sourceNode's render block already applies gain.
                // So, the tapped audio implicitly includes gain.

                DispatchQueue.main.async {
                    strongChannel.averagePower = dbPower
                }
            }
        }
        updateOverallPlayingStatus() // Set initial state

        do {
            try engine.start()
        } catch {
            print("❌ Audio engine failed to start: \(error)")
        }
    }

    private func updateOverallPlayingStatus() {
        let currentlyPlaying = channels.contains { $0.isPlaying }
        if self.isAnyChannelPlaying != currentlyPlaying {
            self.isAnyChannelPlaying = currentlyPlaying
        }
    }

    // Call this method if you need to clean up, e.g., if engine can be stopped/reconfigured
    func cleanup() {
        channelCancellables.forEach { $0.cancel() }
        channelCancellables.removeAll()
        for channel in channels {
            channel.sourceNode.removeTap(onBus: 0)
        }
        // engine.stop() if needed
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
