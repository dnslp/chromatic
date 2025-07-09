import SnapshotTesting
import SwiftUI
import UIKit
import XCTest
@testable import Chromatic

final class TunerViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        diffTool = "ksdiff"
    }

    func testTunerView() {
        let defaultTunerData = TunerData() // In tune
        let sharpTunerData = TunerData(pitch: 443, amplitude: 0.5) // Approx +11.8 cents (A4=440) -> Should be Green/Yellow
        let verySharpTunerData = TunerData(pitch: 448, amplitude: 0.5) // Approx +31 cents -> Should be Yellow/Red
        let flatTunerData = TunerData(pitch: 437, amplitude: 0.5) // Approx -11.9 cents -> Should be Green/Yellow
        let veryFlatTunerData = TunerData(pitch: 432, amplitude: 0.5) // Approx -31.7 cents -> Should be Yellow/Red

        let testCases: [(name: String, data: TunerData)] = [
            ("inTune", defaultTunerData),
            ("sharp", sharpTunerData),
            ("verySharp", verySharpTunerData),
            ("flat", flatTunerData),
            ("veryFlat", veryFlatTunerData)
        ]

        for testCase in testCases {
            let view = TunerView(
                tunerData: testCase.data,
                modifierPreference: .preferSharps,
                selectedTransposition: 0
            )
            .environmentObject(UserProfileManager())
            for device in SnapshotDevice.all {
                assertSnapshot(
                    matching: view,
                    as: .image(device.config, .light),
                    named: "\(device.fastlaneName)-\(testCase.name)-light"
                )
                assertSnapshot(
                    matching: view,
                    as: .image(device.config, .dark),
                    named: "\(device.fastlaneName)-\(testCase.name)-dark"
                )
            }
        }
    }
}

private extension Snapshotting where Value: View, Format == UIImage {
    static func image(_ config: ViewImageConfig, _ style: UIUserInterfaceStyle) -> Snapshotting {
        return .image(
            perceptualPrecision: 0.99,
            layout: .device(config: config),
            traits: .init(userInterfaceStyle: style)
        )
    }
}

private struct SnapshotDevice {
    /// SnapshotTesting Config.
    let config: ViewImageConfig
    /// Name for this display family used by Fastlane
    /// See https://github.com/fastlane/fastlane/blob/2.172.0/spaceship/lib/assets/displayFamilies.json
    let fastlaneName: String

    static var all: [SnapshotDevice] {
        [
            SnapshotDevice(config: .iPhoneSe, fastlaneName: "iphone4"),
            SnapshotDevice(config: .iPhone8, fastlaneName: "iphone6"),
            SnapshotDevice(config: .iPhone8Plus, fastlaneName: "iphone6Plus"),
            SnapshotDevice(config: .iPhoneX, fastlaneName: "iphone58"),
            SnapshotDevice(config: .iPhoneXsMax, fastlaneName: "iphone65"),
            SnapshotDevice(config: .iPadMini, fastlaneName: "ipad"),
            SnapshotDevice(config: .iPadPro10_5, fastlaneName: "ipad105"),
            SnapshotDevice(config: .iPadPro11, fastlaneName: "ipadPro11"),
            SnapshotDevice(config: .iPadPro12_9, fastlaneName: "ipadPro129")
        ]
    }
}
