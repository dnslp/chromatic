// PlayerView.swift
// SwiftUI playlist + playback controls

import SwiftUI
// import MicrophonePitchDetector // No longer needed

struct PlayerView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    // @ObservedObject var pitchDetector: MicrophonePitchDetector // No longer needed
    @Binding var modifierPreference: ModifierPreference // This might also be removable if MiniTunerView is gone
    @Binding var selectedTransposition: Int // This might also be removable if MiniTunerView is gone

    var body: some View {
        VStack {
            // Mini tuner pinned at the top (functionality removed)
            // Text("MiniTuner Placeholder") // Optional: if you want to signify where it was

            Text("📀 Playlist")
                .font(.headline)
                .padding(.top, 8)

            // Song list scroll area
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(Array(audioPlayer.songList.enumerated()), id: \.offset) { index, name in
                        HStack {
                            Text(name)
                                .onTapGesture { audioPlayer.select(at: index) }
                            Spacer()
                            if name == audioPlayer.currentSong {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        Divider()
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 500)

            Spacer()

            // Playback controls
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
        // Pin PlayerView to the top
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(
            audioPlayer: AudioPlayer(),
            // pitchDetector: MicrophonePitchDetector(), // No longer needed
            modifierPreference: .constant(.preferSharps), // Keep for now, but could be removed if not used otherwise
            selectedTransposition: .constant(0) // Keep for now
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
