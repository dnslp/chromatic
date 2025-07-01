import SnapshotTesting
import SwiftUI
import UIKit
import XCTest
@testable import Chromatic

final class MatchedNoteViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        diffTool = "ksdiff"
    }

    func testMatchedNoteView() {
        let testCases: [(name: String, distanceInCents: Float, note: ScaleNote, octave: Int)] = [
            ("inTune", 0, .A, 4),
            ("slightlySharp", 7, .CSharp_DFlat, 4), // Should be yellow
            ("verySharp", 20, .FSharp_GFlat, 3),   // Should be red
            ("slightlyFlat", -7, .E, 2),           // Should be yellow
            ("veryFlat", -20, .G, 5)             // Should be red
        ]

        // Using iPhone8 as a representative device and standard layout.
        // Adding light and dark mode testing.
        let lightImageConfig = Snapshotting<MatchedNoteView, UIImage>.image(
            layout: .device(config: .iPhone8),
            traits: .init(userInterfaceStyle: .light)
        )
        let darkImageConfig = Snapshotting<MatchedNoteView, UIImage>.image(
            layout: .device(config: .iPhone8),
            traits: .init(userInterfaceStyle: .dark)
        )

        for testCase in testCases {
            let match = ScaleNote.Match(
                note: testCase.note,
                octave: testCase.octave,
                distance: Frequency.MusicalDistance(cents: testCase.distanceInCents)
            )

            let view = MatchedNoteView(
                match: match,
                modifierPreference: .preferSharps // Preference doesn't affect color, so keep it consistent
            )

            assertSnapshot(
                matching: view,
                as: lightImageConfig,
                named: "\(testCase.name)-light"
            )
            assertSnapshot(
                matching: view,
                as: darkImageConfig,
                named: "\(testCase.name)-dark"
            )
        }
    }
}
