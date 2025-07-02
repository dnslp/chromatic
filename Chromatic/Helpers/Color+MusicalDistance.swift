import SwiftUI

extension Color {
    /// Color used to display a musical distance that is imperceptible (aka "in tune").
    static var imperceptibleMusicalDistance: Color { .green }
    /// Color used to display a musical distance that is slightly perceptible.
    static var slightlyPerceptibleMusicalDistance: Color { .yellow }
    /// Color used to display a musical distance that is perceptible (aka "out of tune").
    static var perceptibleMusicalDistance: Color { .red }

    /// Determines the appropriate color based on the musical distance.
    ///
    /// - Parameter distance: The musical distance to evaluate.
    /// - Returns: A `Color` representing the perceptibility of the distance.
    static func color(for distance: Frequency.MusicalDistance) -> Color {
        let absoluteCents = fabsf(distance.cents)

        if absoluteCents <= Frequency.MusicalDistance.imperceptibleThreshold {
            return .imperceptibleMusicalDistance
        } else if absoluteCents <= Frequency.MusicalDistance.slightlyPerceptibleThreshold {
            return .slightlyPerceptibleMusicalDistance
        } else {
            return .perceptibleMusicalDistance
        }
    }
}
