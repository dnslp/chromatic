// AudioPlayer.swift
// WAV/MP3-file player for SwiftUI with folder-detection and fade in/out

import Foundation
import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentSong: String = ""
    @Published var songList: [String] = []

    private var player: AVAudioPlayer?
    private var songURLs: [URL] = []
    private var currentIndex: Int = 0
    private var fadeTimer: Timer?

    // Fade settings
    private let fadeDuration: TimeInterval = 0.5
    private let stepInterval: TimeInterval = 0.05

    init() {
        configureAudioSession()
        // Attempt multiple subdirectory locations
        let subs = ["Audio", "Models/Audio", nil]
        for sub in subs {
            if let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: sub),
               !urls.isEmpty {
                songURLs = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
                break
            }
        }

        // Build display list
        songList = songURLs.map { $0.deletingPathExtension().lastPathComponent }

        if songURLs.isEmpty {
            currentSong = "No Audio Found"
        } else {
            currentSong = songList[currentIndex]
            loadSong()
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Using .playAndRecord as the app also uses the microphone.
            // Adding .allowBluetoothA2DP for high-quality Bluetooth audio.
            // Adding .defaultToSpeaker to match AudioEngine's behavior.
            // Keeping .mixWithOthers if it was implicitly desired through AudioEngine.
            var options: AVAudioSession.CategoryOptions = [.allowBluetoothA2DP, .defaultToSpeaker]
            // Check if mixWithOthers should be included - this depends on overall app requirements
            // For now, let's assume it's desired if AudioEngine uses it.
            // A more robust solution would be a shared configuration.
            // If MicrophonePitchDetector is guaranteed to run its config, this might be redundant here,
            // but it's safer to be consistent.
            options.insert(.mixWithOthers) // Add this to be consistent with AudioEngine

            try session.setCategory(.playAndRecord, mode: .default, options: options)
            try session.setActive(true)
        } catch {
            print("⚠️ AVAudioSession setup failed: \(error)")
        }
    }

    private func loadSong() {
        guard !songURLs.isEmpty else { return }
        let url = songURLs[currentIndex]
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 1.0
            player?.prepareToPlay()
        } catch {
            print("❌ Failed to load \(url.lastPathComponent): \(error)")
        }
    }

    func select(at index: Int) {
        guard index != currentIndex,
              index >= 0,
              index < songURLs.count else { return }
        fadeOut {
            self.currentIndex = index
            self.currentSong = self.songList[index]
            self.loadSong()
            self.fadeIn()
        }
    }

    func play() {
        configureAudioSession()  // ensure session active before playing
        guard player != nil, !isPlaying else { return }
        fadeIn()
    }

    func pause() {
        guard isPlaying else { return }
        fadeOut()
    }

    func next() {
        guard !songURLs.isEmpty else { return }
        let next = (currentIndex + 1) % songURLs.count
        select(at: next)
    }

    func previous() {
        guard !songURLs.isEmpty else { return }
        let prev = (currentIndex - 1 + songURLs.count) % songURLs.count
        select(at: prev)
    }

    // MARK: - Fade In/Out

    private func fadeIn() {
        guard let player = player else { return }
        fadeTimer?.invalidate()
        player.volume = 0
        player.play()
        let step = Float(stepInterval / fadeDuration)
        var vol: Float = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            vol += step
            player.volume = min(vol, 1.0)
            if player.volume >= 1.0 {
                timer.invalidate()
                self.isPlaying = true
            }
        }
    }

    private func fadeOut(completion: @escaping () -> Void = {}) {
        guard let player = player, isPlaying else {
            completion()
            return
        }
        fadeTimer?.invalidate()
        let step = Float(stepInterval / fadeDuration)
        var vol = player.volume
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            vol -= step
            player.volume = max(vol, 0.0)
            if player.volume <= 0 {
                timer.invalidate()
                player.pause()
                self.isPlaying = false
                completion()
            }
        }
    }
}
