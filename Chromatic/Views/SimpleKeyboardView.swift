import SwiftUI
import Keyboard
import Tonic    // You MUST explicitly import this!

struct SimpleKeyboardView: View {
    /// MIDI note number to highlight (e.g. 60 = C4), or nil for no highlight
    let highlightedMIDINote: Int?

    /// Build the Tonic.Pitch to compare against
    private var highlightedPitch: Tonic.Pitch? {
        guard let midi = highlightedMIDINote else { return nil }
        return Tonic.Pitch(intValue: midi)
    }

    var body: some View {
        Keyboard(
            layout: .piano(pitchRange: Tonic.Pitch(0)...Tonic.Pitch(83)), // C0…B6
            latching: false,
            noteOn:    { _, _ in },   // no-op
            noteOff:   { _    in }    // no-op
        ) { (pitch: Tonic.Pitch, _: Bool) in
            KeyboardKey(
                pitch: pitch,
                isActivated: highlightedPitch == pitch,
                text: "",           // no label on the key face
                flatTop: true,      // piano-style keys
                alignment: .bottom
            )
        }
        .frame(height: 25)
        .disabled(true)   // display-only
    }
}

struct SimpleKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Highlight Middle C (MIDI 60)
            SimpleKeyboardView(highlightedMIDINote: 60)
            // Highlight A4 (MIDI 69)
            SimpleKeyboardView(highlightedMIDINote: 69)
            // No highlight
            SimpleKeyboardView(highlightedMIDINote: nil)
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
