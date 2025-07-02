// MixerEngine.swift
// AVAudioEngine-based 4-track mixer for SwiftUI

import Foundation
import AVFoundation
import Combine

class MixerEngine: ObservableObject {
    struct Track: Identifiable {
        let id = UUID()
        var name: String = "Empty"
        var url: URL?
        var volume: Float = 1.0
        let playerNode: AVAudioPlayerNode
        var buffer: AVAudioPCMBuffer?
    }

    @Published var tracks: [Track] = []
    private let engine: AVAudioEngine
    private let mainMixer = AVAudioMixerNode()

    init(engine: AVAudioEngine, numberOfTracks: Int = 4) {
        self.engine = engine
        // Attach main mixer
        engine.attach(mainMixer)
        engine.connect(mainMixer, to: engine.mainMixerNode, format: nil)

        // Create player nodes
        for _ in 0..<numberOfTracks {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mainMixer, format: nil)
            tracks.append(Track(playerNode: node))
        }

    }

    /// Load an audio file into a track
    func loadFile(_ url: URL, for trackIndex: Int) {
        guard tracks.indices.contains(trackIndex) else { return }
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let length = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length) else { return }
            try file.read(into: buffer)

            // Update track
            tracks[trackIndex].url = url
            tracks[trackIndex].name = url.deletingPathExtension().lastPathComponent
            tracks[trackIndex].buffer = buffer
        } catch {
            print("❌ Track \(trackIndex) file load error: \(error)")
        }
    }

    /// Start all tracks synchronously
    func playAll() {
        let startTime = engine.outputNode.lastRenderTime?.sampleTime
        for i in tracks.indices {
            guard let buffer = tracks[i].buffer else { continue }
            let node = tracks[i].playerNode
            node.volume = tracks[i].volume
            node.scheduleBuffer(buffer, at: nil, options: .loops)
            node.play()
        }
    }

    func pauseAll() {
        tracks.forEach { $0.playerNode.pause() }
    }

    func stopAll() {
        tracks.forEach { $0.playerNode.stop() }
    }

    func setVolume(_ volume: Float, for trackIndex: Int) {
        guard tracks.indices.contains(trackIndex) else { return }
        tracks[trackIndex].volume = volume
        tracks[trackIndex].playerNode.volume = volume
    }
}
