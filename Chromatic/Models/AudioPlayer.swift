// AudioPlayer.swift
// WAV-file player for SwiftUI with folder-detection and fade in/out

import Foundation
import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentSong: String = ""
    @Published var songList: [String] = []
    @Published var volume: Float = 1.0 // Target volume
    @Published var averagePower: Float = -160.0 // For VU meter, dBFS

    private var player: AVAudioPlayer?
    private var songURLs: [URL] = []
    private var currentIndex: Int = 0
    private var fadeTimer: Timer?
    private var meterUpdateTimer: Timer?

    // Fade settings
    private let fadeDuration: TimeInterval = 0.5
    private let stepInterval: TimeInterval = 0.05

    init() {
        // Attempt multiple subdirectory locations
        let subs = ["Audio", "Models/Audio", nil]
        for sub in subs {
            if let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: sub), !urls.isEmpty {
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

    private func loadSong() {
        guard !songURLs.isEmpty else { return }
        let url = songURLs[currentIndex]
        do {
            // Stop metering before changing the player instance
            stopMetering()

            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // Loop indefinitely
            player?.volume = self.volume // Initialize with current target volume
            player?.isMeteringEnabled = true // Enable metering
            player?.prepareToPlay()

            // If it was playing, and a new song is selected, start metering for the new song if it auto-plays
            // For now, metering is started by fadeIn()
        } catch {
            print("❌ Failed to load \(url.lastPathComponent): \(error)")
        }
    }

    // Select a track directly
    func select(at index: Int) {
        guard index != currentIndex, index >= 0, index < songURLs.count else { return }
        fadeOut {
            self.currentIndex = index
            self.currentSong = self.songList[index]
            self.loadSong()
            self.fadeIn()
        }
    }

    func play() {
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

    func setVolume(_ newVolume: Float) {
        let clampedVolume = min(max(newVolume, 0.0), 1.0) // Ensure volume is between 0 and 1
        self.volume = clampedVolume
        // If player is active and not currently fading, apply volume directly
        if player?.isPlaying == true && fadeTimer == nil {
            player?.volume = self.volume
        }
        // If currently fading in, the fade logic will pick up the new target self.volume.
        // If currently fading out, it will continue to fade to 0. This behavior can be adjusted if needed.
    }

    // MARK: - Metering
    private func startMetering() {
        stopMetering() // Ensure no existing timer is running
        guard player != nil else { return }
        meterUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player, player.isPlaying else { return }
            player.updateMeters()
            self.averagePower = player.averagePower(forChannel: 0)
        }
    }

    private func stopMetering() {
        meterUpdateTimer?.invalidate()
        meterUpdateTimer = nil
        // Reset power when stopping, or let it hold the last value?
        // For a live VU meter, it's often better to go to min value when stopped.
        self.averagePower = -160.0
    }


    // MARK: - Fade In/Out

    private func fadeIn() {
        guard let player = player else { return }
        fadeTimer?.invalidate() // Cancel any existing fade
        player.volume = 0 // Start from silent
        player.play()
        startMetering() // Start metering when playback begins

        let targetVolume = self.volume // Use the class property as target
        if targetVolume == 0 { // If target volume is 0, just set to 0 and don't "fade"
            player.volume = 0
            self.isPlaying = true // It's "playing" at volume 0
            return
        }

        let step = Float(targetVolume) * Float(stepInterval / fadeDuration) // Scale step by target volume
        var currentFadeVolume: Float = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            currentFadeVolume += step
            if currentFadeVolume >= targetVolume {
                player.volume = targetVolume
                timer.invalidate()
                self.fadeTimer = nil
                self.isPlaying = true
            } else {
                player.volume = currentFadeVolume
            }
        }
    }

    private func fadeOut(completion: @escaping () -> Void = {}) {
        guard let player = player, (isPlaying || fadeTimer != nil) else { // Also consider if it's in midst of fading in
            completion()
            return
        }

        fadeTimer?.invalidate() // Cancel any existing fade (like an ongoing fadeIn)
        self.isPlaying = false // Set immediately, actual stop happens after fade

        let startingVolume = player.volume // Fade from current actual volume
        if startingVolume == 0 { // If already silent
            player.pause()
            self.stopMetering()
            self.fadeTimer = nil
            completion()
            return
        }

        let step = startingVolume * Float(stepInterval / fadeDuration) // Scale step by starting volume
        var currentFadeVolume = startingVolume

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); completion(); return }
            currentFadeVolume -= step
            if currentFadeVolume <= 0 {
                player.volume = 0
                player.pause()
                self.stopMetering()
                timer.invalidate()
                self.fadeTimer = nil
                completion()
            } else {
                player.volume = currentFadeVolume
            }
        }
    }
}
