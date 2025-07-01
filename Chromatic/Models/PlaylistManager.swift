//
//  PlaylistManager.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//
import Foundation
import AVFoundation

class PlaylistManager: ObservableObject {
    // For single track playback
    @Published var currentTrackFile: AVAudioFile?
    @Published var currentTrackName: String?
    @Published var isPlaying: Bool = false // Represents state for single or synchronous playback

    // Player node for single track playback
    private var singleTrackPlayerNode: AVAudioPlayerNode?

    // For multiple synchronous tracks
    private var syncPlayerNodes: [AVAudioPlayerNode] = []
    private var syncAudioFiles: [AVAudioFile] = []
    // We'll use a single mixer for all playlist audio, whether single or sync
    private var playlistMixerNode = AVAudioMixerNode()

    private var audioEngine: AVAudioEngine?
    private var playlist: [URL] = [] // Still useful for browsing individual tracks
    private var currentIndex: Int = 0 // For single track selection

    init() {
        loadPlaylist() // Loads available tracks into `playlist`
    }

    func attachTo(engine: AVAudioEngine) {
        guard self.audioEngine == nil else {
            print("PlaylistManager is already attached to an audio engine.")
            return
        }
        self.audioEngine = engine

        // Attach the common playlist mixer to the engine
        engine.attach(playlistMixerNode)

        // Connect the playlist mixer to the engine's output node
        let outputNode = engine.outputNode
        // Ensure a compatible format for the connection to the output node.
        // Using the output node's input format for bus 0 is a common approach.
        let mixerConnectionFormat = outputNode.inputFormat(forBus: 0)
        engine.connect(playlistMixerNode, to: outputNode, format: mixerConnectionFormat)
        print("PlaylistManager: Connected playlistMixerNode to outputNode.")

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Error starting shared audio engine in PlaylistManager: \(error.localizedDescription)")
            }
        }
    }

    private func extractFrequency(from filename: String) -> Double? {
        // Filename example: G3-196Hz-60BPM.mp3 or Eb2-77.782Hz-60BPM.wav
        let components = filename.split(separator: "-")
        if components.count > 1 {
            let frequencyComponent = String(components[1]) // e.g., "196Hz" or "77.782Hz"
            if let hzRange = frequencyComponent.range(of: "Hz", options: .caseInsensitive) {
                let numberPart = String(frequencyComponent[..<hzRange.lowerBound])
                return Double(numberPart)
            }
        }
        print("Warning: Could not extract frequency from filename: \(filename)")
        return nil // Return nil if frequency cannot be extracted
    }

    private func loadPlaylist() {
        var filesWithFrequency: [(url: URL, frequency: Double)] = []
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        // Construct the path to the "Chromatic/Models/Audio" directory relative to the bundle root.
        // This assumes the "Audio" folder within "Models" is copied into the app bundle resources.
        // You might need to adjust this if your project structure or build phases are different.
        // A common practice is to have a "Sounds" or "AudioFiles" group in Xcode that gets copied.
        // For this example, let's assume "Chromatic/Models/Audio" is correctly placed in bundle.

        // First, try to access "Chromatic/Models/Audio" directly if it's a bundle resource path
        var audioFilesDirectoryURL = bundleURL.appendingPathComponent("Chromatic/Models/Audio")

        // Fallback: If "Chromatic/Models/Audio" is not found (e.g. if bundle structure is flatter),
        // try accessing "Audio" directly, assuming it might be copied to the bundle root.
        if !fileManager.fileExists(atPath: audioFilesDirectoryURL.path) {
            print("Did not find audio at \(audioFilesDirectoryURL.path), trying bundleURL.appendingPathComponent(\"Audio\")")
            audioFilesDirectoryURL = bundleURL.appendingPathComponent("Audio") // Common for resource folders
        }
        
        // Further Fallback: If still not found, try resourcesPath which might be where loose files go.
         if !fileManager.fileExists(atPath: audioFilesDirectoryURL.path), let resourcesPath = Bundle.main.resourcePath {
             audioFilesDirectoryURL = URL(fileURLWithPath: resourcesPath) // Search entire resourcesPath
             print("Still not found, trying resourcesPath: \(audioFilesDirectoryURL.path)")
         }


        do {
            let directoryContents = try fileManager.contentsOfDirectory(at: audioFilesDirectoryURL, includingPropertiesForKeys: nil, options: [])
            let audioExtensions = ["mp3", "wav", "m4a"] // Add other extensions if needed

            for url in directoryContents {
                if audioExtensions.contains(url.pathExtension.lowercased()) {
                    let filename = url.deletingPathExtension().lastPathComponent
                    if let frequency = extractFrequency(from: filename) {
                        filesWithFrequency.append((url: url, frequency: frequency))
                    } else {
                        // Optionally handle files that don't match the naming convention
                        // For now, they are just ignored by the sorting logic if frequency is nil
                        print("Could not parse frequency for \(filename), it will not be sorted by frequency.")
                        // To include them unsorted (e.g. at the end), assign a very high default frequency:
                        // filesWithFrequency.append((url: url, frequency: Double.greatestFiniteMagnitude))
                    }
                }
            }

            // Sort by frequency in ascending order
            filesWithFrequency.sort { $0.frequency < $1.frequency }

            // Populate the playlist with sorted URLs
            self.playlist = filesWithFrequency.map { $0.url }

            print("Sorted playlist:")
            for fileTuple in filesWithFrequency {
                print("- \(fileTuple.url.lastPathComponent) (Frequency: \(fileTuple.frequency))")
            }

        } catch {
            print("Error loading audio files from \(audioFilesDirectoryURL.path): \(error.localizedDescription)")
        }

        if !playlist.isEmpty {
            prepareTrack(at: 0)
        } else {
            print("Playlist is empty. No tracks to play. Check audio files path and content.")
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
        // This method is now for single track playback.
        // It will create, configure, and use `singleTrackPlayerNode`.
        // It should also ensure any synchronous playback is stopped.

        stopSynchronousPlayback() // Stop any sync playback first.

        if currentTrackFile == nil {
            print("No track loaded. Attempting to prepare one for single playback.")
            if !playlist.isEmpty {
                prepareTrack(at: currentIndex) // This sets currentTrackFile
            } else {
                print("Playlist is empty. Cannot prepare single track.")
                return
            }
        }

        guard let trackToPlay = currentTrackFile else {
            print("Still no single track available to play.")
            return
        }

        // Stop and reset existing single track player node if it exists
        if let existingPlayer = singleTrackPlayerNode {
            existingPlayer.stop()
            audioEngine?.detach(existingPlayer)
            self.singleTrackPlayerNode = nil
        }

        let playerNode = AVAudioPlayerNode()
        self.singleTrackPlayerNode = playerNode
        engine.attach(playerNode)

        // Connect to the common playlistMixerNode
        guard let format = trackToPlay.processingFormat as AVAudioFormat? else {
            print("Error: Could not get processing format for single track \(trackToPlay.url.lastPathComponent).")
            // Fallback or error handling
            let commonFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) ?? AVAudioFormat()
            engine.connect(playerNode, to: playlistMixerNode, format: commonFormat)
            // We might choose to not proceed if the format is unknown.
            return
        }
        engine.connect(playerNode, to: playlistMixerNode, format: format)

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Could not start audio engine for single track: \(error.localizedDescription)")
                return
            }
        }

        playerNode.scheduleFile(trackToPlay, at: nil) { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
                // self?.nextTrack() // Optional: auto-play next
            }
        }
        playerNode.play()
        isPlaying = true
    }

    func pause() {
        // Pauses whatever is currently playing (single or sync)
        if !(syncPlayerNodes.isEmpty) {
            for playerNode in syncPlayerNodes where playerNode.isPlaying {
                playerNode.pause()
            }
        } else if let playerNode = singleTrackPlayerNode, playerNode.isPlaying {
            playerNode.pause()
        }
        isPlaying = false
    }

    func nextTrack() {
        guard !playlist.isEmpty else { return }
        stopAllPlayback() // Stop current playback (single or sync) before switching track
        let nextIndex = (currentIndex + 1) % playlist.count
        prepareTrack(at: nextIndex) // This sets currentTrackFile and currentTrackName
        // User needs to press play() again to start the new track.
    }

    func previousTrack() {
        guard !playlist.isEmpty else { return }
        stopAllPlayback() // Stop current playback (single or sync) before switching track
        let prevIndex = (currentIndex - 1 + playlist.count) % playlist.count
        prepareTrack(at: prevIndex)
        // User needs to press play() again to start the new track.
    }

    // --- Methods for Synchronous Playback ---

    func playSynchronously(urls: [URL]) {
        guard let engine = audioEngine, !urls.isEmpty else {
            print("Audio engine not attached or no URLs provided for synchronous playback.")
            return
        }

        stopAllPlayback() // Stop any current playback (single or sync)

        var tempPlayerNodes: [AVAudioPlayerNode] = []
        var tempAudioFiles: [AVAudioFile] = []

        for url in urls {
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let playerNode = AVAudioPlayerNode()

                engine.attach(playerNode)
                // Connect each player node to the common playlistMixerNode
                guard let format = audioFile.processingFormat as AVAudioFormat? else {
                     print("Could not get processing format for \(url.lastPathComponent) for sync playback.")
                     // Fallback to a common format if specific one fails, or skip this file
                     let commonFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) ?? AVAudioFormat()
                     engine.connect(playerNode, to: playlistMixerNode, format: commonFormat)
                     // Consider not adding this file if its format is problematic
                     continue
                 }
                engine.connect(playerNode, to: playlistMixerNode, format: format)

                tempAudioFiles.append(audioFile)
                tempPlayerNodes.append(playerNode)

            } catch {
                print("Error loading audio file \(url.lastPathComponent) for sync playback: \(error.localizedDescription)")
                // Continue to next file, or decide to abort all if one fails
            }
        }

        guard !tempPlayerNodes.isEmpty else {
            print("No audio files successfully loaded for synchronous playback.")
            return
        }

        self.syncAudioFiles = tempAudioFiles
        self.syncPlayerNodes = tempPlayerNodes

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Could not start audio engine for sync playback: \(error.localizedDescription)")
                // Clean up attached nodes if engine fails to start
                for node in tempPlayerNodes { engine.detach(node) }
                self.syncPlayerNodes.removeAll()
                self.syncAudioFiles.removeAll()
                return
            }
        }

        var allScheduledSuccessfully = true
        for (index, playerNode) in syncPlayerNodes.enumerated() {
            let audioFile = syncAudioFiles[index]
            playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    // Check if all sync players have finished
                    if self?.syncPlayerNodes.allSatisfy({ !$0.isPlaying }) ?? false {
                        if self?.isPlaying == true && !(self?.syncPlayerNodes.isEmpty ?? true) {
                           self?.isPlaying = false
                           print("All synchronous tracks finished.")
                        }
                    }
                }
            }
        }
        
        // Only play if all files were scheduled
        if allScheduledSuccessfully {
            for playerNode in syncPlayerNodes {
                playerNode.play()
            }
            isPlaying = true
            currentTrackFile = nil // Clear single track info
            currentTrackName = "Synchronous Playback"
        } else {
            print("Not all files could be scheduled for synchronous playback. Aborting.")
            // Cleanup nodes that might have been attached but not played
            stopSynchronousPlayback()
        }
    }

    private func stopSingleTrackPlayback() {
        if let playerNode = singleTrackPlayerNode {
            playerNode.stop()
            audioEngine?.detach(playerNode)
            singleTrackPlayerNode = nil
        }
    }

    private func stopSynchronousPlayback() {
        for playerNode in syncPlayerNodes {
            playerNode.stop()
            audioEngine?.detach(playerNode)
        }
        syncPlayerNodes.removeAll()
        syncAudioFiles.removeAll()
    }

    func stopAllPlayback() {
        stopSingleTrackPlayback()
        stopSynchronousPlayback()
        isPlaying = false
    }
}

