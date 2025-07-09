// PlayerView.swift
// SwiftUI playlist + playback controls

import SwiftUI
import MicrophonePitchDetector

struct PlayerView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    @ObservedObject var pitchDetector: MicrophonePitchDetector
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int

    var body: some View {
        VStack {
            // Mini tuner pinned at the top
//            MiniTunerView(
//                tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude),
//                modifierPreference: $modifierPreference,
//                selectedTransposition: $selectedTransposition
//            )
//            .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5) // mirror opacity behavior
//            .animation(.easeInOut, value: pitchDetector.didReceiveAudio)
//            .frame(maxWidth: .infinity)

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
            VStack {
                HStack(spacing: 40) { // Main controls: prev, play/pause, next
                    Button(action: { audioPlayer.previous() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 35))
                    }

                    Button(action: {
                        audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play()
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                    }

                    Button(action: { audioPlayer.next() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 35))
                    }
                }
                .padding(.bottom, 20)

                HStack(spacing: 50) { // Secondary controls: shuffle, repeat
                    Button(action: { audioPlayer.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 22))
                            .foregroundColor(audioPlayer.isShuffled ? .accentColor : .gray)
                    }

                    Button(action: { audioPlayer.cycleRepeatMode() }) {
                        Image(systemName: repeatModeIcon())
                            .font(.system(size: 22))
                            .foregroundColor(audioPlayer.repeatMode == .none ? .gray : .accentColor)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        // Pin PlayerView to the top
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func repeatModeIcon() -> String {
        switch audioPlayer.repeatMode {
        case .none:
            return "repeat"
        case .one:
            return "repeat.1"
        case .all:
            return "repeat" // Using "repeat" for ".all" as well, but it will be colored by foregroundColor
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(
            audioPlayer: AudioPlayer(),
            pitchDetector: MicrophonePitchDetector(),
            modifierPreference: .constant(.preferSharps),
            selectedTransposition: .constant(0)
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
