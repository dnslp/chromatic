// PlayerView.swift
// SwiftUI playlist + playback controls

import SwiftUI

struct PlayerView: View {
    @ObservedObject var audioPlayer: AudioPlayer

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
            .frame(maxHeight: 200)

            Spacer()

            // Volume Slider and VU Meter
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "speaker.fill")
                    Slider(value: Binding(
                        get: { audioPlayer.volume },
                        set: { audioPlayer.setVolume($0) }
                    ), in: 0...1) {
                        Text("Volume") // Accessibility label
                    }
                    Image(systemName: "speaker.wave.3.fill")
                }
                .padding(.horizontal)

                ProgressView(value: normalizePower(audioPlayer.averagePower), total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .frame(height: 8)
                    .padding(.horizontal)
                Text(String(format: "%.1f dB", audioPlayer.averagePower))
                    .font(.caption)
            }
            .padding(.bottom, 20)


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

    // Helper to normalize dBFS to 0-1 range for ProgressView
    // Typical range for AVAudioPlayer averagePower is -160 to 0 dBFS.
    private func normalizePower(_ power: Float) -> Double {
        let minDb: Float = -60.0 // Show some dynamics, -160 is too low for typical visualization
        let maxDb: Float = 0.0

        // Clamp power to the desired range
        let clampedPower = max(minDb, min(power, maxDb))

        // Normalize to 0-1
        let normalized = (clampedPower - minDb) / (maxDb - minDb)
        return Double(normalized)
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock audio player for preview that has some values
        let mockPlayer = AudioPlayer()
        mockPlayer.songList = ["Song 1", "Song 2", "Another Song Title That Is A Bit Longer"]
        mockPlayer.currentSong = "Song 1"
        mockPlayer.volume = 0.7
        mockPlayer.averagePower = -20 // Example power level
        mockPlayer.isPlaying = true

        return PlayerView(audioPlayer: mockPlayer)
    }
}
