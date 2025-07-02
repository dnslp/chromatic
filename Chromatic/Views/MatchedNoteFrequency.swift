import SwiftUI

struct MatchedNoteFrequency: View {
    let frequency: Frequency

    var body: some View {
        Text(frequency.localizedString())
            .foregroundColor(.secondary).font(.system(size: 24, weight: .bold, design: .rounded))
    }
}

struct MatchedNoteFrequency_Previews: PreviewProvider {
    static var previews: some View {
        MatchedNoteFrequency(frequency: 440.0)
            .previewLayout(.sizeThatFits)
    }
}
