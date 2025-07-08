//
//  Harmonic.swift
//  Chromatic
//
//  Created by Jules on 10/24/23.
//

import Foundation

/// Represents a single harmonic frequency.
struct Harmonic: Equatable, Codable, Identifiable {
    /// A unique identifier for the harmonic.
    let id = UUID()

    /// The frequency of the harmonic in Hz.
    var frequency: Double

    /// The relationship of this harmonic to the fundamental frequency (e.g., "2nd harmonic", "octave").
    var label: String

    /// The harmonic number (e.g., 1 for fundamental, 2 for second harmonic, etc.).
    var number: Int

    init(frequency: Double, label: String, number: Int) {
        self.frequency = frequency
        self.label = label
        self.number = number
    }
}
