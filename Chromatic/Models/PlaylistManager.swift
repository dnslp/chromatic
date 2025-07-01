import Foundation
import AVFoundation

class PlaylistManager: ObservableObject {
    @Published var songs: [URL] = []
    @Published var currentSongIndex: Int? = nil
    @Published var isPlaying: Bool = false
    @Published var currentSongTitle: String? = nil

    private var audioPlayer: AVAudioPlayer?

    init() {
        // Notification for when audio finishes playing
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func loadSongs(from directory: URL) {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            songs = fileURLs.filter { $0.pathExtension == "mp3" || $0.pathExtension == "wav" } // Add more extensions if needed
            if !songs.isEmpty {
                currentSongIndex = 0
                prepareToPlay()
            }
        } catch {
            print("Error loading songs: \(error)")
        }
    }

    func loadSongsFromBundle() {
        // Songs should be in a folder (e.g., "Music") added to the project and included in "Copy Bundle Resources".
        // This makes them available in the main bundle.
        guard let musicDirectoryURL = Bundle.main.url(forResource: "Music", withExtension: nil) else {
            print("Music directory not found in bundle. Make sure to add a folder named 'Music' with your audio files to the project and include it in 'Copy Bundle Resources'.")
            // Attempt to load from a potential 'Sounds' directory as a fallback, or other common names.
            // This is just an example; ideally, the user configures this properly.
            if let soundsDirectoryURL = Bundle.main.url(forResource: "Sounds", withExtension: nil) {
                 print("Attempting to load from 'Sounds' directory.")
                 loadSongs(from: soundsDirectoryURL)
            } else {
                print("Neither 'Music' nor 'Sounds' directory found. No songs will be loaded from bundle.")
            }
            return
        }
        loadSongs(from: musicDirectoryURL)
    }


    private func prepareToPlay() {
        guard let index = currentSongIndex, index < songs.count else { return }
        let songURL = songs[index]
        currentSongTitle = songURL.deletingPathExtension().lastPathComponent
        do {
            // Stop previous player if any
            audioPlayer?.stop()
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: songURL)
            audioPlayer?.delegate = self // Set delegate to handle playback finishing
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error preparing audio player: \(error)")
        }
    }

    func play() {
        guard let player = audioPlayer else {
            if currentSongIndex == nil, !songs.isEmpty {
                currentSongIndex = 0 // Start from the first song if nothing is selected
                prepareToPlay()
                play() // Recursive call to play after preparing
            }
            return
        }
        if !player.isPlaying {
            player.play()
            isPlaying = true
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func nextSong() {
        guard var index = currentSongIndex else { return }
        index += 1
        if index >= songs.count {
            index = 0 // Loop back to the first song
        }
        currentSongIndex = index
        prepareToPlay()
        play()
    }

    func previousSong() {
        guard var index = currentSongIndex else { return }
        index -= 1
        if index < 0 {
            index = songs.count - 1 // Loop back to the last song
        }
        currentSongIndex = index
        prepareToPlay()
        play()
    }

    @objc private func audioPlayerDidFinishPlaying() {
        // This is called when the AVAudioPlayer finishes playing a song naturally.
        // For some reason, the delegate method audioPlayerDidFinishPlaying(_:successfully:)
        // is not reliably called in all scenarios, especially with backgrounding.
        // Using the notification is a more robust way.
        isPlaying = false
        nextSong() // Automatically play the next song
    }
}

extension PlaylistManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // This delegate method might not always be called.
        // The notification observer `audioPlayerDidFinishPlaying` is more reliable.
        if flag {
            isPlaying = false
            // It's generally better to call nextSong() from the notification observer
            // to avoid potential double calls if both are triggered.
            // However, if the notification is missed for some reason, this can be a fallback.
            // For now, we rely on the notification.
            // nextSong()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "unknown error")")
        isPlaying = false
        // Optionally, try to play the next song or inform the user.
    }
}
