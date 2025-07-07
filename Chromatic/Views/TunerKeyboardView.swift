//
//  TunerKeyboardView.swift
//  Chromatic
//
//  Created by David Nyman on 7/7/25.
//

import SwiftUI
import Keyboard    // re-exports Tonic.Pitch for KeyboardKey
import Tonic       // brings in Tonic.Pitch explicitly

struct TunerKeyboardView: View {
    let tunerData: TunerData

    // The octave to display (C4–B4)
    private let octave = 4
    private var midiNotes: [Int] { (0...11).map { octave * 12 + $0 } }

    // Heights for white vs. black keys
    private let whiteKeyHeight: CGFloat = 72
    private let blackKeyHeight: CGFloat = 48

    // Convert Hz → MIDI (0…127)
    private var currentMidi: Int {
        let hz = tunerData.pitch.measurement.value
        guard hz > 0 else { return -1 }
        return Int(round(69 + 12 * log2(hz / 440.0)))
    }

    // Semitone offsets for black keys in an octave
    private let blackOffsets: Set<Int> = [1, 3, 6, 8, 10]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(midiNotes, id: \.self) { midi in
                let semitone = midi % 12
                let isBlack = blackOffsets.contains(semitone)
                let pitch = Tonic.Pitch(intValue: midi)

                VStack(spacing: 0) {
                    // Provide `text:` so `flatTop:` is parsed correctly
                    KeyboardKey(
                        pitch: pitch,
                        isActivated: midi == currentMidi,
                        text: "",
                        flatTop: !isBlack   // white keys flatTop=false, black flatTop=true
                    )
                    .frame(width: 28, height: isBlack ? blackKeyHeight : whiteKeyHeight)

                    // Label only the C key
                    if semitone == 0 {
                        Text("C\(octave)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(height: 14)
                    } else {
                        Color.clear.frame(height: 14)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct TunerKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        // A4 = 440 Hz → MIDI 69 → highlights the “A” key in C4–B4
        let fake = TunerData(pitch: 440, amplitude: 0.5)
        TunerKeyboardView(tunerData: fake)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
