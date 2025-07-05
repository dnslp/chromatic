import SwiftUI

struct CurrentNoteMarker: View {
    let frequency: Frequency
    let distance: Frequency.MusicalDistance
    let showFrequencyText: Bool

    // Base constants
    private let baseWidth: CGFloat   = 30    // your “ideal” width when perfectly in tune
    private let baseHeight: CGFloat  = 120
    private let totalWidth: CGFloat  = 36
    private let totalHeight: CGFloat = 100

    // Animation driver for the glow
    @State private var glowOn = false

    // MARK: 1) Compute the fill hue from note name
    private var fillColor: Color {
        let hz = frequency.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let semitone = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(semitone)/12.0, saturation: 1, brightness: 1)
    }

    // MARK: 2) Compute glow color & intensity based on cent deviation
    private var glowColor: Color {
        let cents = abs(Double(distance.cents))
        switch cents {
        case ...5:   return fillColor
        case ...15:  return fillColor.opacity(0.7)
        default:     return .white
        }
    }

    // MARK: 3) New dynamicWidth that shrinks out-of-tune
    private var dynamicWidth: CGFloat {
        // at 0¢ → factor = 1.0; at 50¢ → factor = 0.5
        let error = min(abs(Double(distance.cents)), 50)
        let factor = 1 - 0.5 * (error / 18)
        return baseWidth * CGFloat(factor)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(width: geo.size.width, height: totalHeight)

                VStack(spacing: 4) {
                    Rectangle()
                        .frame(width: dynamicWidth, height: baseHeight)
                        .cornerRadius(dynamicWidth / 2)
                        .foregroundColor(fillColor.opacity(distance.isPerceptible ? 1 : 0.6))
                        // glow shadow
                        .shadow(color: glowColor.opacity(glowOn ? 0.9 : 0.3),
                                radius: glowOn ? 20 : 10)
                        .animation(.easeInOut(duration: 0.9), value: distance.cents)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                            ) {
                                glowOn.toggle()
                            }
                        }

//                    if distance.cents > 1 {
//                        Image(systemName: "arrowtriangle.right.fill")
//                            .foregroundColor(glowColor)
//                            .shadow(color: glowColor.opacity(glowOn ? 0.9 : 0.3),
//                                    radius: glowOn ? 10 : 2)
//                    } else if distance.cents < -1 {
//                        Image(systemName: "arrowtriangle.left.fill")
//                            .foregroundColor(glowColor)
//                            .shadow(color: glowColor.opacity(glowOn ? 0.9 : 0.3),
//                                    radius: glowOn ? 10 : 2)
//                    }
                }
                .frame(width: totalWidth)
                .position(
                    x: geo.size.width/2 + CGFloat(distance.cents/50)*geo.size.width/2,
                    y: totalHeight/2
                )
            }

            if showFrequencyText {
                Text(frequency.localizedString())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, totalHeight + 8)
            }
        }
        .frame(height: totalHeight + (showFrequencyText ? 30 : 0))
        .alignmentGuide(.noteTickCenter) { $0[VerticalAlignment.center] }
    }
}

struct CurrentNoteMarker_Previews: PreviewProvider {
    static var previews: some View {
        let makeDistance: (Double) -> Frequency.MusicalDistance = { Frequency.MusicalDistance(cents: Float($0)) }
        Group {
            CurrentNoteMarker(frequency: Frequency(floatLiteral: 440),
                              distance: makeDistance(0),
                              showFrequencyText: true)
                .previewDisplayName("In Tune")

            CurrentNoteMarker(frequency: Frequency(floatLiteral: 442),
                              distance: makeDistance(30),
                              showFrequencyText: true)
                .previewDisplayName("Sharp")

            CurrentNoteMarker(frequency: Frequency(floatLiteral: 437),
                              distance: makeDistance(-15),
                              showFrequencyText: true)
                .previewDisplayName("Flat")
        }
        .previewLayout(.fixed(width: 300, height: 200))
        .background(Color(UIColor.systemBackground))
    }
}
