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
    var value: Double?
    
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
        notes: String? = nil
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
    }
}
