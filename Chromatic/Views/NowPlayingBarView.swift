import SwiftUI

struct NowPlayingBarView: View {
    @ObservedObject var audioPlayer: AudioPlayer

    var body: some View {
        Group {
            if !audioPlayer.currentSong.isEmpty && audioPlayer.currentSong != "No Audio Found" {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Now Playing: \(audioPlayer.currentSong)")
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.thinMaterial) // Use a material background for a modern look
                    Divider()
                }
            } else {
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: audioPlayer.currentSong) // Animate changes
    }
}

struct NowPlayingBarView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock AudioPlayer for preview
        let mockAudioPlayer = AudioPlayer()
        // Simulate a song playing for preview
        // mockAudioPlayer.currentSong = "Sample Song Title"
        // mockAudioPlayer.isPlaying = true
        // To see the "No Audio Found" state or empty state, comment out the above lines

        // Preview with a song
        let playingPlayer = AudioPlayer()
        playingPlayer.songList = ["Preview Song 1", "Preview Song 2"]
        if !playingPlayer.songList.isEmpty { // Ensure songList is not empty before accessing index 0
            playingPlayer.currentSong = playingPlayer.songList[0]
            playingPlayer.isPlaying = true
        }

        // Preview when no song is loaded/available
        let emptyPlayer = AudioPlayer()
        // emptyPlayer.songList = [] // Already default
        emptyPlayer.currentSong = "No Audio Found" // Simulate this state

        // Preview with a default initialized player
        let defaultPlayer = AudioPlayer()

        return Group {
            VStack {
                Text("Preview: Song Playing")
                NowPlayingBarView(audioPlayer: playingPlayer)
                Text("App Content Below")
            }
            .padding()
            .previewDisplayName("Song Playing")

            VStack {
                Text("Preview: No Audio Found")
                NowPlayingBarView(audioPlayer: emptyPlayer)
                Text("App Content Below")
            }
            .padding()
            .previewDisplayName("No Audio Found")

            VStack {
                Text("Preview: Initial State (No song selected yet)")
                NowPlayingBarView(audioPlayer: defaultPlayer)
                Text("App Content Below")
            }
            .padding()
            .previewDisplayName("Initial State")
        }
        .previewLayout(.sizeThatFits)
    }
}
