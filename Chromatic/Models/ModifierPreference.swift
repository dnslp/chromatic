// ModifierPreference.swift
// Defines how enharmonic notes should be displayed to the user.

/// Represents the user's preference for note modifiers when a pitch can be
/// spelled with sharps or flats.
enum ModifierPreference: Int, Identifiable, CaseIterable {
    /// Display sharps instead of flats when both are possible (e.g. F# rather than Gb).
    case preferSharps
    /// Display flats instead of sharps when both are possible (e.g. Gb rather than F#).
    case preferFlats

    /// Returns the opposite of the current preference. Useful for UI toggle buttons.
    var toggled: ModifierPreference {
        switch self {
        case .preferSharps:
            return .preferFlats
        case .preferFlats:
            return .preferSharps
        }
    }

    /// Conformance to ``Identifiable`` using the raw integer value as the ID.
    var id: Int { rawValue }
}
