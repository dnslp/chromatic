// PlayerView.swift
// SwiftUI playlist + playback controls

import SwiftUI
import MicrophonePitchDetector // Import to use MicrophonePitchDetector

struct PlayerView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    @ObservedObject var pitchDetector: MicrophonePitchDetector // Add pitchDetector

    var body: some View {
        VStack {
            Text("📀 Playlist")
                .font(.headline)
                .padding(.top)

            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(Array(audioPlayer.songList.enumerated()), id: \ .offset) { index, name in
                        HStack {
                            Text(name)
                            Spacer()
                            if name == audioPlayer.currentSong {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            audioPlayer.select(at: index)
                        }
                        Divider()
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 500)

            Spacer() // Pushes MiniTunerView and controls to the bottom

            // Add MiniTunerView here
            MiniTunerView(pitchDetector: pitchDetector)
                .padding(.horizontal) // Add some horizontal padding
                .padding(.bottom, 10) // Space before playback controls

            HStack(spacing: 50) {
                Button(action: { audioPlayer.previous() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 30))
                }

                Button(action: {
                    audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play()
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                }

                Button(action: { audioPlayer.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 30))
                }
            }
            .padding(.bottom, 30)
        }
        // The .task for activating pitchDetector is in MiniTunerView itself,
        // so it will activate when this view appears if not already active.
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide both dependencies for the preview
        PlayerView(audioPlayer: AudioPlayer(), pitchDetector: MicrophonePitchDetector())
    }
}
