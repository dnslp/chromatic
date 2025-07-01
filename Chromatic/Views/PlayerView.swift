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

            Spacer()

            // MiniTunerView will be added here later
            MiniTunerView(
                tunerData: TunerData(pitch: pitchDetector.pitch, amplitude: pitchDetector.amplitude),
                modifierPreference: $modifierPreference,
                selectedTransposition: $selectedTransposition
            )
            .opacity(pitchDetector.didReceiveAudio ? 1 : 0.5) // Mirror opacity behavior from TunerScreen
            .animation(.easeInOut, value: pitchDetector.didReceiveAudio) // Mirror animation

            Spacer()

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
    }
}
