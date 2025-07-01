//
//  PlaylistManager.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//
import Foundation
import AVFoundation

class PlaylistManager: ObservableObject {
    @Published var currentTrackFile: AVAudioFile? // Renamed for clarity
    @Published var currentTrackName: String?
    @Published var isPlaying: Bool = false

    private var audioPlayerNode = AVAudioPlayerNode()
    private var audioEngine: AVAudioEngine? // Optional, will be set externally
    private var playlist: [URL] = []
    private var currentIndex: Int = 0

    // Initializer no longer sets up its own engine immediately
    init() {
        loadPlaylist()
    }

    // Call this method to provide the shared AVAudioEngine
    // and connect the player node to it.
    func attachTo(engine: AVAudioEngine) {
        guard self.audioEngine == nil else {
            print("PlaylistManager is already attached to an audio engine.")
            // Optionally, disconnect from the old engine and connect to the new one
            // For now, we assume it's only attached once.
            return
        }

        self.audioEngine = engine
        
        // Create a dedicated mixer for our playlist audio
        let playlistMixer = AVAudioMixerNode()
        engine.attach(playlistMixer)
        
        // Attach the player node to the provided engine
        engine.attach(audioPlayerNode)

        // Connect player node to our dedicated playlistMixer
        // Use a common stereo format, similar to what MicrophonePitchDetector's AudioEngine uses internally.
        // This helps ensure compatibility before a specific file is scheduled on audioPlayerNode.
        guard let commonFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) else {
            fatalError("PlaylistManager: Could not create common AVAudioFormat.") // Should not happen
        }
        engine.connect(audioPlayerNode, to: playlistMixer, format: commonFormat)

        // Connect our playlistMixer to the engine's output node
        let outputNode = engine.outputNode
        // Use a common format for the connection to the output node,
        // or the output node's input format for bus 0.
        let mixerConnectionFormat = outputNode.inputFormat(forBus: 0)
        engine.connect(playlistMixer, to: outputNode, format: mixerConnectionFormat)
        print("PlaylistManager: Connected audioPlayerNode -> playlistMixer -> outputNode.")

        // Ensure the engine is running. The MicrophonePitchDetector should have started it.
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Error starting shared audio engine in PlaylistManager: \(error.localizedDescription)")
            }
        }
        
        // If a track was pre-loaded and waiting, schedule it now
        if let trackFile = self.currentTrackFile, audioEngine?.isRunning == true {
            // Stop any existing playback and reset before scheduling new file
            audioPlayerNode.stop()
            audioPlayerNode.reset()
            
            audioPlayerNode.scheduleFile(trackFile, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    // Optionally, auto-play next or handle end of track
                }
            }
        }
    }

    private func loadPlaylist() {
        // For now, let's assume some dummy audio files in the bundle
        // In a real app, you'd load these from user's library or a server
        let song1URL = Bundle.main.url(forResource: "song1", withExtension: "mp3")
        let song2URL = Bundle.main.url(forResource: "song2", withExtension: "m4a") // Example with different extension

        var validURLs: [URL] = []
        if let url1 = song1URL {
            validURLs.append(url1)
        } else {
            print("Warning: song1.mp3 not found in bundle.")
        }
        if let url2 = song2URL {
            validURLs.append(url2)
        } else {
            print("Warning: song2.m4a not found in bundle.")
        }
        
        self.playlist = validURLs

        if !playlist.isEmpty {
            prepareTrack(at: 0)
        } else {
            print("Playlist is empty. No tracks to play.")
        }
    }

    private func prepareTrack(at index: Int) {
        guard !playlist.isEmpty, index >= 0, index < playlist.count else {
            print("Invalid track index or empty playlist.")
            self.currentTrackFile = nil
            self.currentTrackName = nil
            return
        }

        let url = playlist[index]
        do {
            let audioFile = try AVAudioFile(forReading: url)
            self.currentTrackFile = audioFile
            // Extract a display name from the URL
            self.currentTrackName = url.deletingPathExtension().lastPathComponent
            self.currentIndex = index
            
            // Ensure audioPlayerNode is not nil and engine is available before scheduling
            // The actual scheduling will happen in attachTo or when play is called
            // if the engine wasn't available at init time.
            // For now, we just set the current track.
            // If the player node is already playing, we might need to stop it before scheduling a new file.
            // However, the typical flow is prepare -> play.

        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
            self.currentTrackFile = nil
            self.currentTrackName = nil
        }
    }

    func play() {
        guard let engine = audioEngine else {
            print("Audio engine not attached to PlaylistManager. Cannot play.")
            return
        }

        // If no track is currently loaded, try to prepare one.
        if currentTrackFile == nil {
            print("No track loaded. Attempting to prepare one.")
            if !playlist.isEmpty {
                prepareTrack(at: currentIndex)
            } else {
                print("Playlist is empty. Cannot prepare track.")
            }
        }

        // Now, after attempting to prepare, check again if a track is available.
        guard let trackToPlay = currentTrackFile else {
            print("Still no track available to play after preparation attempt or playlist is empty.")
            return
        }
        
        // Ensure the track is scheduled before playing, especially if it wasn't scheduled during attachTo (e.g. engine wasn't running)
        // or if play is called after a pause and the buffer needs to be rescheduled.
        // A more robust solution might check audioPlayerNode.playerTime or a similar property
        // to see if it's already scheduled and at the end.
        // For simplicity, we'll re-schedule if not currently playing. This handles starting from scratch
        // or continuing after a track finished.
        if !audioPlayerNode.isPlaying || audioPlayerNode.playerTime == nil /* crude check for needing scheduling */ {
            // Stop and reset before scheduling a new file or re-scheduling the current one
            audioPlayerNode.stop()
            audioPlayerNode.reset()
            audioPlayerNode.scheduleFile(currentTrackFile!, at: nil) { [weak self] in
                 DispatchQueue.main.async {
                    self?.isPlaying = false
                    // Consider calling nextTrack() here for auto-advancing playlist
                }
            }
        }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Could not start audio engine: \(error.localizedDescription)")
                return
            }
        }

        audioPlayerNode.play()
        isPlaying = true
    }

    func pause() {
        // No need to check audioEngine for pause, as node operations are safe.
        audioPlayerNode.pause()
        isPlaying = false
    }

    func nextTrack() {
        guard !playlist.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % playlist.count
        prepareTrack(at: nextIndex)
        if isPlaying { // If it was playing, start the new track
            play()
        }
    }

    func previousTrack() {
        guard !playlist.isEmpty else { return }
        let prevIndex = (currentIndex - 1 + playlist.count) % playlist.count
        prepareTrack(at: prevIndex)
        if isPlaying { // If it was playing, start the new track
            play()
        }
    }
    
    // Call this method to allow the audio engine to run alongside microphone input
    func connectToEngine(_ engine: AVAudioEngine) {
        // Disconnect from internal engine's main mixer if previously connected
        audioEngine?.disconnectNodeOutput(audioPlayerNode)

        // Connect to the provided engine's main mixer
        let mainMixer = engine.mainMixerNode
        engine.connect(audioPlayerNode, to: mainMixer, format: mainMixer.outputFormat(forBus: 0))
        
        // Use the external engine going forward
        self.audioEngine = engine
    }
}

