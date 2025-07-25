import Foundation

// MARK: - Type Definition

struct Frequency: Equatable {
    /// The underlying frequency `Measurement`.
    private(set) var measurement: Measurement<UnitFrequency>
    
    func harmonics(count: Int) -> [Frequency] {
        (1...count).map { i in
            Frequency(floatLiteral: self.measurement.value * Double(i))
        }
    }

    /// The distance between frequencies in cents: https://en.wikipedia.org/wiki/Cent_%28music%29
    struct MusicalDistance: Hashable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        /// Underlying float value. Between -50 and +50.
        let cents: Float

        /// Humans can distinguish a difference in pitch of about 5–6 cents:
        /// https://en.wikipedia.org/wiki/Cent_%28music%29#Human_perception
        // Threshold definitions based on common musical practice and existing UI logic.
        static let imperceptibleThreshold: Float = 6.0 // Cents. Corresponds to "in tune".
        static let slightlyPerceptibleThreshold: Float = 15.0 // Cents. Corresponds to "slightly out of tune".
        // Anything above slightlyPerceptibleThreshold is considered "perceptible" or "out of tune".

        var isPerceptible: Bool { fabsf(cents) > MusicalDistance.imperceptibleThreshold }

        /// A distance is flat if it is less than zero.
        var isFlat: Bool { cents < 0 }

        /// A distance is sharp if it is greater than zero.
        var isSharp: Bool { cents > 0 }

        /// The distance in a full octave.
        static var octave: MusicalDistance { MusicalDistance(cents: 1200) }

        init(cents: Float) {
            self.cents = cents
        }

        init(floatLiteral value: Float) {
            cents = value
        }

        init(integerLiteral value: Int) {
            cents = Float(value)
        }
    }

    /// Calculate distance to given frequency in musical cents.
    ///
    /// - parameter frequency: Frequency to compare against.
    ///
    /// - returns: The distance in cents.
    func distance(to frequency: Frequency) -> MusicalDistance {
        MusicalDistance(
            cents: MusicalDistance.octave.cents * log2f(Float(frequency.measurement.value / measurement.value))
        )
    }
}

// MARK: - Expressible By Literal Protocols

extension Frequency: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        measurement = Measurement(value: value, unit: .hertz)
    }
}

extension Frequency: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        measurement = Measurement(value: Double(value), unit: .hertz)
    }
}

// MARK: - Localized String

private let kFrequencyFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.numberFormatter.minimumFractionDigits = 1
    formatter.numberFormatter.maximumFractionDigits = 1
    return formatter
}()

extension Frequency {
    func localizedString() -> String {
        kFrequencyFormatter.string(from: measurement)
    }
}

// MARK: - Comparable

extension Frequency: Comparable {
    static func < (lhs: Frequency, rhs: Frequency) -> Bool {
        lhs.measurement < rhs.measurement
    }
}

// MARK: - Octave Operations

extension Frequency {
    /// Returns the current frequency shifted by increasing or decreasing in discrete octave increments.
    ///
    /// - parameter octaves: The number of octaves to transpose this frequency. Can be positive or negative.
    ///
    /// - returns: Octave shifted frequency.
    func shifted(byOctaves octaves: Int) -> Frequency {
        var copy = self
        copy.shift(byOctaves: octaves)
        return copy
    }

    /// Shifts the frequency by increasing or decreasing in discrete octave increments.
    ///
    /// - parameter octaves: The number of octaves to transpose this frequency. Can be positive or negative.
    mutating func shift(byOctaves octaves: Int) {
        if octaves != 0 {
            measurement.value *= pow(2.0, Double(octaves))
        }
    }

    /// Computes the distance in octaves between the current frequency and the specified frequency. Truncates if
    /// distance is not exact octaves.
    ///
    /// - parameter frequency: Frequency to compare.
    ///
    /// - returns: Distance in octaves to specified frequency.
    func distanceInOctaves(to frequency: Frequency) -> Int {
        Int(distance(to: frequency).cents / MusicalDistance.octave.cents)
    }

    /// Creates a new frequency that's offset by the musical distance specified.
    ///
    /// - parameter distance: The musical distance to offset this frequency.
    ///
    /// - returns: A new frequency that's offset by the musical distance specified.
    func adding(_ distance: MusicalDistance) -> Frequency {
        var newMeasurement = measurement
        newMeasurement.value *= Double(exp2(distance.cents / MusicalDistance.octave.cents))
        return Frequency(measurement: newMeasurement)
    }
}
