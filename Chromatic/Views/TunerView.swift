import SwiftUI

struct TunerView: View {
    let tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    @AppStorage("HidesTranspositionMenu")
    private var hidesTranspositionMenu = false

    var body: some View {
#if os(watchOS)
        ZStack(alignment: Alignment(horizontal: .noteCenter, vertical: .noteTickCenter)) {
            NoteTicks(tunerData: tunerData, showFrequencyText: false)

            MatchedNoteView(
                match: match,
                modifierPreference: modifierPreference
            )
            .focusable()
            .digitalCrownRotation(
                Binding(
                    get: { Float(selectedTransposition) },
                    set: { selectedTransposition = Int($0) }
                ),
                from: 0,
                through: Float(ScaleNote.allCases.count - 1),
                by: 1
            )
        }
#else
        VStack(alignment: .noteCenter) {
            if !hidesTranspositionMenu {
                HStack {
                    TranspositionMenu(selectedTransposition: $selectedTransposition)
                        .padding()

                    Spacer()
                }
            }

            Spacer()

            MatchedNoteView(
                match: match,
                modifierPreference: modifierPreference
            )

            MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)

            NoteTicks(tunerData: tunerData, showFrequencyText: true)

            Text("Amplitude: \(String(format: "%.2f", tunerData.amplitude))")
                .padding()

            // Playlist Controls
            if let playlistManager = tunerData.playlistManager {
                PlaylistControlsView(playlistManager: playlistManager)
                    .padding()
            }

            Spacer()
        }
#endif
    }
}

// New struct for Playlist Controls
struct PlaylistControlsView: View {
    @ObservedObject var playlistManager: PlaylistManager

    var body: some View {
        VStack {
            if let title = playlistManager.currentSongTitle {
                Text("Now Playing: \(title)")
                    .font(.caption)
                    .padding(.bottom, 2)
            } else {
                Text("No song loaded")
                    .font(.caption)
                    .padding(.bottom, 2)
            }
            HStack {
                Button(action: { playlistManager.previousSong() }) {
                    Image(systemName: "backward.fill")
                }
                .disabled(playlistManager.songs.isEmpty)

                Button(action: {
                    if playlistManager.isPlaying {
                        playlistManager.pause()
                    } else {
                        playlistManager.play()
                    }
                }) {
                    Image(systemName: playlistManager.isPlaying ? "pause.fill" : "play.fill")
                }
                .disabled(playlistManager.songs.isEmpty)

                Button(action: { playlistManager.nextSong() }) {
                    Image(systemName: "forward.fill")
                }
                .disabled(playlistManager.songs.isEmpty)
            }
            .font(.title2) // Adjust icon size
        }
    }
}


struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: TunerData(pitch: 440, amplitude: 0.5), // Added example amplitude for preview
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
    }
}
