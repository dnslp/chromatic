import SwiftUI

struct AmplitudeBarView: View {
    let amplitude: Double
    let maxHeight: CGFloat = 100 // Max height of the bar

    var body: some View {
        VStack {
            Spacer() // Pushes the bar to the bottom
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.blue) // Bar color
                .frame(width: 20, height: min(CGFloat(amplitude) * maxHeight, maxHeight)) // Calculate height based on amplitude
        }
        .frame(height: maxHeight) // Ensure consistent height for the view
    }
}

struct AmplitudeBarView_Previews: PreviewProvider {
    static var previews: some View {
        AmplitudeBarView(amplitude: 0.75)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
