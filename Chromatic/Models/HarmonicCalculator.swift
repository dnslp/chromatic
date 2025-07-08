//
//  HarmonicCalculator.swift
//  Chromatic
//
//  Created by Jules on 10/24/23.
//

import Foundation

/// A utility for calculating harmonics of a fundamental frequency.
struct HarmonicCalculator {

    /// Calculates a specified number of harmonics for a given fundamental frequency.
    ///
    /// - Parameters:
    ///   - f0: The fundamental frequency in Hz.
    ///   - count: The number of harmonics to calculate (including the fundamental).
    /// - Returns: An array of `Harmonic` objects. Returns an empty array if count is less than 1.
    static func calculateHarmonics(f0: Double, count: Int) -> [Harmonic] {
        guard count >= 1 else { return [] }

        var harmonics: [Harmonic] = []

        for i in 1...count {
            let frequency = f0 * Double(i)
            let label: String
            switch i {
            case 1:
                label = "Fundamental"
            case 2:
                label = "2nd Harmonic (Octave)"
            case 3:
                label = "3rd Harmonic (Perfect Fifth)"
            case 4:
                label = "4th Harmonic (2 Octaves)"
            case 5:
                label = "5th Harmonic (Major Third)"
            case 6:
                label = "6th Harmonic (Perfect Fifth)"
            case 7:
                label = "7th Harmonic (Minor Seventh)"
            case 8:
                label = "8th Harmonic (3 Octaves)"
            // Add more specific labels if needed, or a general one.
            default:
                label = "\(i)th Harmonic"
            }
            harmonics.append(Harmonic(frequency: frequency, label: label, number: i))
        }
        return harmonics
    }
}
