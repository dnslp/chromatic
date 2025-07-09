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
        playingPlayer.currentSong = "Preview Song 1"
        playingPlayer.isPlaying = true

        // Preview when no song is loaded/available
        let emptyPlayer = AudioPlayer()
        emptyPlayer.songList = []
        emptyPlayer.currentSong = "No Audio Found"

        VStack {
            NowPlayingBarView(audioPlayer: playingPlayer)
            Text("App Content Below (Playing)")
            Spacer()
            NowPlayingBarView(audioPlayer: emptyPlayer)
            Text("App Content Below (No Audio)")
            Spacer()
            NowPlayingBarView(audioPlayer: AudioPlayer()) // Default init state
            Text("App Content Below (Initial State)")
        }
        .previewLayout(.sizeThatFits)
    }
}
