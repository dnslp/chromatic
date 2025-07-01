import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var playlistManager: PlaylistManager

    // Define specific URLs for synchronous playback
    // These assume the files are in the "Audio" subdirectory of the bundle resources
    // (as per PlaylistManager's loading logic fallback)
    // If they are in "Chromatic/Models/Audio", the subdirectory path needs to be adjusted here
    // or ensure PlaylistManager's primary path works.
    // For robustness, we'll try to construct URLs similar to how TunerScreen did for testing.

    private var syncUrl1: URL? {
        // Try "Chromatic/Models/Audio" first, then "Audio"
        if let url = Bundle.main.url(forResource: "C3-130.81Hz-60BPM", withExtension: "mp3", subdirectory: "Chromatic/Models/Audio") {
            return url
        }
        return Bundle.main.url(forResource: "C3-130.81Hz-60BPM", withExtension: "mp3", subdirectory: "Audio")
    }

    private var syncUrl2: URL? {
        if let url = Bundle.main.url(forResource: "A3-220-60BPM", withExtension: "mp3", subdirectory: "Chromatic/Models/Audio") {
            return url
        }
        return Bundle.main.url(forResource: "A3-220-60BPM", withExtension: "mp3", subdirectory: "Audio")
    }

    var body: some View {
        VStack {
            Text(playlistManager.currentTrackName ?? "No track selected")
                .padding()

            HStack {
                Button(action: {
                    playlistManager.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                }
                .padding()

                Button(action: {
                    if playlistManager.isPlaying {
                        playlistManager.pause()
                    } else {
                        // If trying to play after pause, it should resume.
                        // If no track was ever played or after stopAllPlayback, currentTrackFile might be nil.
                        // play() handles preparing the current track if needed.
                        playlistManager.play()
                    }
                }) {
                    Image(systemName: playlistManager.isPlaying ? "pause.fill" : "play.fill")
                }
                .padding()

                Button(action: {
                    playlistManager.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                }
                .padding()
            }

            Button("Play C3 and A3 Synced") {
                guard let url1 = syncUrl1, let url2 = syncUrl2 else {
                    print("PlayerView: Could not find C3 or A3 for synchronous playback.")
                    // Optionally, show an alert to the user
                    return
                }
                playlistManager.playSynchronously(urls: [url1, url2])
            }
            .padding()

            Button("Stop All Playback") {
                playlistManager.stopAllPlayback()
            }
            .padding()
        }
        .onAppear {
            // This is to ensure the view reflects the initial state of PlaylistManager
            // For example, if a track was auto-played from TunerScreen's .task
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock PlaylistManager for previewing purposes
        let mockPlaylistManager = PlaylistManager()
        // You might want to simulate a loaded track for the preview
        // mockPlaylistManager.prepareTrack(at: 0) // if playlist is loaded

        // Simulate attaching to an engine for previews if necessary, though UI might not need full functionality
        // let tempEngine = AVAudioEngine()
        // mockPlaylistManager.attachTo(engine: tempEngine)

        PlayerView()
            .environmentObject(mockPlaylistManager)
    }
}
