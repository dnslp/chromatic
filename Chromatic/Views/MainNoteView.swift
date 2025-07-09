import SwiftUI

/// Displays the main detected note in large, bold text.
///
/// - Parameter note: The note name to show.
/// - Note: The `.noteCenter` alignment guide forwards the text's horizontal
///   center so other views can align precisely with this note.
struct MainNoteView: View {
    /// The note name to display.
    let note: String

    var body: some View {
        Text(note)
            .font(.system(size: 100, design: .rounded))
            .bold()
            .alignmentGuide(.noteCenter) { dimensions in
                dimensions[HorizontalAlignment.center]
            }
    }
}

struct MainNoteView_Previews: PreviewProvider {
    static var previews: some View {
        MainNoteView(note: "A")
            .previewLayout(.sizeThatFits)
    }
}
