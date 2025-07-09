import SwiftUI

/// Displays the frequency for the matched note beneath the note name.
///
/// `frequency.localizedString()` formats the value using
/// `MeasurementFormatter` so the decimal separator and unit match the user's
/// locale. The view uses a bold rounded font and the secondary color to keep it
/// legible while allowing the main note label to stand out.
struct MatchedNoteFrequency: View {
    /// Frequency to display in hertz.
    let frequency: Frequency

    var body: some View {
        // Show a single line of text with one decimal place and localized units
        Text(frequency.localizedString())
            .foregroundColor(.secondary)
            .font(.system(size: 24, weight: .bold, design: .rounded))
    }
}

struct MatchedNoteFrequency_Previews: PreviewProvider {
    static var previews: some View {
        MatchedNoteFrequency(frequency: 440.0)
            .previewLayout(.sizeThatFits)
    }
}
