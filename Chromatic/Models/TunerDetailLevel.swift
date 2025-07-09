import Foundation

struct TunerDetailLevel: OptionSet {
    let rawValue: Int

    static let pitchDisplay   = TunerDetailLevel(rawValue: 1 << 0)
    static let centeringRing  = TunerDetailLevel(rawValue: 1 << 1)
    static let harmonicGraph  = TunerDetailLevel(rawValue: 1 << 2)
    static let recordControls = TunerDetailLevel(rawValue: 1 << 3)
    static let profileMenu    = TunerDetailLevel(rawValue: 1 << 4)

    static let basic: TunerDetailLevel = [.pitchDisplay, .centeringRing]
    static let all: TunerDetailLevel = [.pitchDisplay, .centeringRing, .harmonicGraph, .recordControls, .profileMenu]
}
