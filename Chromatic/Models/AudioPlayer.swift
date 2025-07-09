// AudioPlayer.swift
// WAV/MP3-file player for SwiftUI with folder-detection and fade in/out

import Foundation
import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentSong: String = ""
    @Published var songList: [String] = []

    // New properties for shuffle and repeat
    @Published var isShuffled: Bool = false
    enum RepeatMode {
        case none, one, all
    }
    @Published var repeatMode: RepeatMode = .none
    @Published var isHeadphonesConnected: Bool = false

    private var player: AVAudioPlayer?
    private var songURLs: [URL] = []
    private var currentIndex: Int = 0
    private var fadeTimer: Timer?
    private var routeChangeObserver: Any? // For AVAudioSession route change notification

    // Fade settings
    private let fadeDuration: TimeInterval = 0.5
    private let stepInterval: TimeInterval = 0.05

    // Store the original, unshuffled order of songs
    private var originalSongURLs: [URL] = []
    private var originalSongList: [String] = []
    private var playHistory: [Int] = [] // For intelligent 'previous' in shuffle mode

    init() {
        configureAudioSession()
        // Attempt multiple subdirectory locations
        let subs = ["Audio", "Models/Audio", nil]
        for sub in subs {
            if let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: sub),
               !urls.isEmpty {
                originalSongURLs = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
                songURLs = originalSongURLs // Initially, songURLs is the original order
                break
            }
        }

        // Build display list
        originalSongList = originalSongURLs.map { $0.deletingPathExtension().lastPathComponent }
        songList = originalSongList // Initially, songList is the original order

        if songURLs.isEmpty {
            currentSong = "No Audio Found"
        } else {
            currentSong = songList[currentIndex]
            loadSong()
        }
        updateHeadphoneStatus() // Initial check
        setupRouteChangeNotification() // Listen for changes
    }

    deinit {
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            // No need to explicitly call setActive(true) here if it's done before playing.
            // However, ensuring it's active before any playback operation is good.
            // Let's keep it, but be mindful it can throw if interrupted.
            try session.setActive(true)
        } catch {
            print("⚠️ AVAudioSession setup failed: \(error)")
        }
    }

    private func updateHeadphoneStatus() {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        isHeadphonesConnected = currentRoute.outputs.contains {
            $0.portType == .headphones ||
            $0.portType == .bluetoothA2DP ||
            $0.portType == .bluetoothLE // For newer Bluetooth headphones
            // Consider .usbAudio if relevant for your app's use cases
        }
        // print("🎧 Headphone status updated: \(isHeadphonesConnected)")
    }

    private func setupRouteChangeNotification() {
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            self?.updateHeadphoneStatus()
        }
    }

    private func loadSong() {
        guard !songURLs.isEmpty else { return }
        let url = songURLs[currentIndex]
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self // Set delegate
            player?.numberOfLoops = 0 // Changed from -1, delegate will handle repeat
            player?.volume = 1.0
            player?.prepareToPlay()
        } catch {
            print("❌ Failed to load \(url.lastPathComponent): \(error)")
        }
    }

    func select(at index: Int) {
        guard index >= 0, index < songURLs.count else { return }
        // Allow selecting the same song to restart it, especially if not playing
        // or to re-apply settings if needed in the future.
        // if index == currentIndex && isPlaying { return }

        if isPlaying {
            fadeOut {
                self.updateCurrentIndexAndSong(to: index)
                self.loadSong()
                self.fadeIn()
            }
        } else {
            // If not playing, just load the song. Play action will handle fadeIn.
            self.updateCurrentIndexAndSong(to: index)
            self.loadSong()
            // If we want it to auto-play on select, uncomment below & ensure configureAudioSession is called
            // self.play()
        }
    }

    private func updateCurrentIndexAndSong(to index: Int) {
        self.currentIndex = index
        self.currentSong = self.songList[index]
        if !isShuffled { // Only add to history if not shuffled, or handle shuffle history differently
            self.playHistory.append(index)
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
        if isShuffled {
            // Simple shuffle: pick a random next song, different from current
            // A more robust shuffle might avoid immediate repeats or use a pre-shuffled list
            var nextIndex = currentIndex
            if songURLs.count > 1 {
                while nextIndex == currentIndex {
                    nextIndex = Int.random(in: 0..<songURLs.count)
                }
            }
            select(at: nextIndex)
        } else {
            let nextIndex = (currentIndex + 1) % songURLs.count
            select(at: nextIndex)
        }
    }

    func previous() {
        guard !songURLs.isEmpty else { return }
        if isShuffled {
            // For shuffle, 'previous' could go to the last played song from history,
            // or just pick another random song.
            // Simple approach: play a different random song.
            // More complex: use playHistory (needs careful management if songs can be selected directly)
            if playHistory.count > 1 {
                playHistory.removeLast() // Remove current song
                if let lastPlayedIndex = playHistory.last {
                    // Ensure this index is still valid if songList was reshuffled.
                    // This simple history won't work well if songURLs changes order during shuffle.
                    // For now, let's just pick another random previous song if shuffled.
                     var prevIndex = currentIndex
                    if songURLs.count > 1 {
                        while prevIndex == currentIndex {
                            prevIndex = Int.random(in: 0..<songURLs.count)
                        }
                    }
                    select(at: prevIndex)
                    return
                }
            }
            // Fallback for shuffle previous if history is short or not helpful
            var prevIndex = currentIndex
            if songURLs.count > 1 {
                while prevIndex == currentIndex {
                    prevIndex = Int.random(in: 0..<songURLs.count)
                }
            }
            select(at: prevIndex)

        } else {
            let prevIndex = (currentIndex - 1 + songURLs.count) % songURLs.count
            select(at: prevIndex)
        }
    }

    // MARK: - Control Methods

    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            // When shuffling, we create a shuffled version of the song list
            // but keep the original order intact for when shuffle is turned off.
            var shuffledIndexes = Array(0..<originalSongURLs.count)
            shuffledIndexes.shuffle()

            // Create new shuffled lists
            songURLs = shuffledIndexes.map { originalSongURLs[$0] }
            songList = shuffledIndexes.map { originalSongList[$0] }

            // Try to find the current playing song in the new shuffled list and update currentIndex
            if let currentURL = player?.url, let newCurrentIndex = songURLs.firstIndex(of: currentURL) {
                currentIndex = newCurrentIndex
                currentSong = songList[newCurrentIndex] // Ensure currentSong reflects the possibly new name if files differ beyond index
            } else if !songList.isEmpty {
                // Fallback if current song not found (e.g. list was empty before), select first in shuffle
                currentIndex = 0
                currentSong = songList[0]
                loadSong() // Load this new song
            }
            playHistory.removeAll() // Reset history on shuffle
            if let player = player, player.isPlaying, !songList.isEmpty {
                 // If playing, and current song was remapped or reset, may need to call select
                 // For now, we assume if a song was playing it continues from its new position if found,
                 // or from start of new shuffled list.
            }

        } else {
            // When turning shuffle off, revert to original order
            let currentPlayingURL = player?.url // Get URL of currently playing song

            songURLs = originalSongURLs
            songList = originalSongList

            // Find the current song in the original list and set currentIndex
            if let url = currentPlayingURL, let originalIndex = songURLs.firstIndex(of: url) {
                currentIndex = originalIndex
                currentSong = songList[originalIndex]
            } else if !songList.isEmpty {
                // Fallback if not found (should not happen if song was from original list)
                currentIndex = 0
                currentSong = songList[0]
                if player?.url != songURLs[0] { // Only reload if the song actually changed
                    loadSong()
                }
            } else if songList.isEmpty {
                currentSong = "No Audio Found"
                player?.stop()
                isPlaying = false
            }
        }
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .none:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .none
        }
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

// MARK: - AVAudioPlayerDelegate
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else {
            // Playback was interrupted or failed
            isPlaying = false
            return
        }

        // Song finished successfully
        self.isPlaying = false // Mark as not playing before deciding next action

        switch repeatMode {
        case .none:
            // If it's the last song and not shuffling (or shuffling and we decide to stop)
            // then stop. Otherwise, play next.
            if !isShuffled && currentIndex == songList.count - 1 {
                // Reached end of playlist, do nothing, playback stops.
                // Optionally, could reset to the beginning or some other behavior.
                // For now, it just stops. User has to press play/next.
                // To reset to start:
                // self.select(at: 0)
                // self.pause() // Ensure it doesn't autoplay
            } else {
                // Not the last song, or shuffling, proceed to next
                next()
                // If next() selects a new song and loads it, we might want to auto-play it.
                // Current next() calls select() which loads but doesn't auto-play.
                // If auto-play is desired after finishing a song (common behavior):
                if !songList.isEmpty { // Ensure there's something to play
                    self.play() // This will call fadeIn
                }
            }
        case .one:
            // Replay the current song
            // select(at: currentIndex) // This would re-load and fade. Simpler:
            player.currentTime = 0
            self.play() // This will call fadeIn
        case .all:
            // Play next song, looping to the beginning if at the end
            next() // next() already handles looping for non-shuffled, and random for shuffled
            if !songList.isEmpty {
                 self.play() // This will call fadeIn
            }
        }
    }
}
