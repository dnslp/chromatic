import SwiftUI

struct DurationProgressView: View {
    let duration: Double
    let maxDuration: Double = 2.0 // Max duration for the progress bar (e.g., 2 seconds)

    var body: some View {
        ProgressView(value: duration, total: maxDuration) {
            Text("In Tune Duration")
        } currentValueLabel: {
            Text(String(format: "%.2fs", duration))
        }
        .progressViewStyle(.linear)
        .padding(.horizontal)
    }
}

struct DurationProgressView_Previews: PreviewProvider {
    static var previews: some View {
        DurationProgressView(duration: 1.5)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
