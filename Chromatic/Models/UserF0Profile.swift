//
//  UserF0Profile.swift
//  Chromatic
//
//  Created by David Nyman on 7/7/25.
//


import Foundation

/// Stores all user-related fundamental frequency (f₀) information.
struct UserF0Profile: Equatable, Codable {
    /// The user’s target/selected fundamental frequency, in Hz (if set)
    var value: Double? {
        didSet {
            updateHarmonics()
        }
    }
    
    /// A display name or label for this f₀ (e.g., "My Chest Voice", "Reference")
    var label: String?
    
    /// The date when this f₀ was set
    var dateSet: Date?
    
    /// Running statistics (optional—expand as needed)
    var mean: Double?
    var median: Double?
    var stdDev: Double?
    var min: Double?
    var max: Double?
    var sampleCount: Int?
    
    /// Whether the user wants to use this f₀ as a tuner reference
    var isActiveReference: Bool
    
    /// User notes or comments (optional)
    var notes: String?
    
    /// The calculated harmonics for the user's f0.
    var harmonics: [Harmonic]?

    // You can add more fields as your app grows!
    
    init(
        value: Double? = nil,
        label: String? = nil,
        dateSet: Date? = nil,
        mean: Double? = nil,
        median: Double? = nil,
        stdDev: Double? = nil,
        min: Double? = nil,
        max: Double? = nil,
        sampleCount: Int? = nil,
        isActiveReference: Bool = true,
        notes: String? = nil,
        harmonics: [Harmonic]? = nil
    ) {
        self.value = value
        self.label = label
        self.dateSet = dateSet
        self.mean = mean
        self.median = median
        self.stdDev = stdDev
        self.min = min
        self.max = max
        self.sampleCount = sampleCount
        self.isActiveReference = isActiveReference
        self.notes = notes
        // Initialize harmonics without calling didSet if initial value is present
        if let initialValue = value, harmonics == nil {
            self.harmonics = HarmonicCalculator.calculateHarmonics(f0: initialValue, count: 8) // Default to 8 harmonics
        } else {
            self.harmonics = harmonics
        }
        // Ensure updateHarmonics is called if value is set during initialization and harmonics were not explicitly passed
        if self.value != nil && harmonics == nil {
             //This ensures that if `value` is set, harmonics are calculated,
             //but avoids double calculation if harmonics are also passed directly.
            if self.harmonics == nil {
                updateHarmonics()
            }
        }
    }

    /// Updates the `harmonics` array based on the current `value` (f0).
    /// Calculates a default number of harmonics (e.g., 8).
    mutating func updateHarmonics() {
        guard let f0 = value else {
            harmonics = nil // Clear harmonics if f0 is not set
            return
        }
        // Calculate a default of 8 harmonics (fundamental + 7 overtones)
        // This number can be made configurable later if needed.
        harmonics = HarmonicCalculator.calculateHarmonics(f0: f0, count: 8)
    }
}
