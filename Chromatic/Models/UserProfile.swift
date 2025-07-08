import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var f0: Double

    // Computed properties for musical intervals based on f0
    var perfectFifth: Double {
        f0 * 1.5
    }

    var perfectFourth: Double {
        f0 * (4.0 / 3.0) // Approximation, can also be f0 * 1.33333...
    }

    var octave: Double {
        f0 * 2.0
    }

    var harmonics: [Double] {
        (1...7).map { Double($0) * f0 }
    }

    // Initializer
    init(id: UUID = UUID(), name: String, f0: Double) {
        self.id = id
        self.name = name
        self.f0 = f0
    }

    // Static function to create a default profile
    static func defaultProfile() -> UserProfile {
        UserProfile(name: "Default Profile", f0: 77.78) // Default f0 from TunerView
    }

    // Equatable conformance
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
}
