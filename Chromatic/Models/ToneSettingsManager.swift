//import Foundation
//
////struct HarmonicAmplitudes: Codable, Equatable {
////    var fundamental: Double = 1.0
////    var harmonic2: Double = 0.10
////    var harmonic3: Double = 0.05
////    var formant: Double = 0.05
////    var noise: Double = 0.00
////}
//
//class ToneSettingsManager: ObservableObject {
//    static let shared = ToneSettingsManager()
//    @Published var amplitudes: HarmonicAmplitudes {
//        didSet { save() }
//    }
//    @Published var attack: Double {
//        didSet { save() }
//    }
//    @Published var release: Double {
//        didSet { save() }
//    }
//
//    private let amplitudesKey = "tonePlayerAmplitudes"
//    private let attackKey = "tonePlayerAttack"
//    private let releaseKey = "tonePlayerRelease"
//
//    private init() {
//        if let data = UserDefaults.standard.data(forKey: amplitudesKey),
//           let loaded = try? JSONDecoder().decode(HarmonicAmplitudes.self, from: data) {
//            amplitudes = loaded
//        } else {
//            amplitudes = HarmonicAmplitudes()
//        }
//        let savedAttack = UserDefaults.standard.object(forKey: attackKey) as? Double
//        attack = savedAttack ?? 0.04
//        let savedRelease = UserDefaults.standard.object(forKey: releaseKey) as? Double
//        release = savedRelease ?? 0.12
//    }
//
//    private func save() {
//        if let data = try? JSONEncoder().encode(amplitudes) {
//            UserDefaults.standard.set(data, forKey: amplitudesKey)
//        }
//        UserDefaults.standard.set(attack, forKey: attackKey)
//        UserDefaults.standard.set(release, forKey: releaseKey)
//    }
//}
