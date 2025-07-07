import SwiftUI

struct AmplitudeView: View {
    @Binding var tunerData: TunerData // Accessing amplitude and potentially micMuted status
    // Consider if micMuted should be a direct binding or part of tunerData
    @Binding var micMuted: Bool

    private let amplitudeBarHeight: CGFloat = 32

    var body: some View {
        HStack(spacing: 8) {
            Text("Level")
                .font(.caption2)
                .foregroundColor(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 6)
                        .foregroundColor(Color.secondary.opacity(0.14))
                    Capsule()
                        .frame(
                            width: geo.size.width *
                                CGFloat(micMuted ? 0 : tunerData.amplitude),
                            height: 6)
                        .foregroundColor(
                            Color(hue: 0.1 - 0.1 * tunerData.amplitude,
                                  saturation: 0.9,
                                  brightness: 0.9)
                        )
                        .animation(.easeInOut, value: tunerData.amplitude)
                }
            }
            .frame(height: amplitudeBarHeight) // Matched to the HStack's frame height for consistency
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .frame(height: amplitudeBarHeight)
        .background(Color(.systemBackground).opacity(0.85))
        .cornerRadius(8)
        .shadow(radius: 2, y: -1) // y was -1, check if this shadow is desired as is
    }
}

struct AmplitudeView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock TunerData that conforms to what AmplitudeView expects
        // For preview purposes, we can use a simple struct or class
        struct MockTunerData {
            var amplitude: Double = 0.5
            // Add other properties if AmplitudeView uses them directly or indirectly
        }

        // Create a @State wrapper for the mock data to allow binding
        @State var mockData = TunerData(pitch: 440, amplitude: 0.7) // Use actual TunerData
        @State var micMuted = false

        AmplitudeView(tunerData: $mockData, micMuted: $micMuted)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
