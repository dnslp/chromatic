//
//  HarmonicCalculatorTests.swift
//  ChromaticTests
//
//  Created by Jules on 10/24/23.
//

import XCTest
@testable import Chromatic

class HarmonicCalculatorTests: XCTestCase {

    func testCalculateHarmonics_validF0_returnsCorrectHarmonics() {
        let f0: Double = 100.0
        let count = 5
        let harmonics = HarmonicCalculator.calculateHarmonics(f0: f0, count: count)

        XCTAssertEqual(harmonics.count, count, "Should return the requested number of harmonics.")

        XCTAssertEqual(harmonics[0].frequency, 100.0, "1st harmonic (fundamental) frequency should be correct.")
        XCTAssertEqual(harmonics[0].number, 1, "1st harmonic number should be correct.")
        XCTAssertEqual(harmonics[0].label, "Fundamental")

        XCTAssertEqual(harmonics[1].frequency, 200.0, "2nd harmonic frequency should be correct.")
        XCTAssertEqual(harmonics[1].number, 2, "2nd harmonic number should be correct.")
        XCTAssertEqual(harmonics[1].label, "2nd Harmonic (Octave)")

        XCTAssertEqual(harmonics[2].frequency, 300.0, "3rd harmonic frequency should be correct.")
        XCTAssertEqual(harmonics[2].number, 3, "3rd harmonic number should be correct.")
        XCTAssertEqual(harmonics[2].label, "3rd Harmonic (Perfect Fifth)")

        XCTAssertEqual(harmonics[3].frequency, 400.0, "4th harmonic frequency should be correct.")
        XCTAssertEqual(harmonics[3].number, 4, "4th harmonic number should be correct.")
        XCTAssertEqual(harmonics[3].label, "4th Harmonic (2 Octaves)")

        XCTAssertEqual(harmonics[4].frequency, 500.0, "5th harmonic frequency should be correct.")
        XCTAssertEqual(harmonics[4].number, 5, "5th harmonic number should be correct.")
        XCTAssertEqual(harmonics[4].label, "5th Harmonic (Major Third)")
    }

    func testCalculateHarmonics_countZero_returnsEmptyArray() {
        let harmonics = HarmonicCalculator.calculateHarmonics(f0: 100.0, count: 0)
        XCTAssertTrue(harmonics.isEmpty, "Should return an empty array if count is 0.")
    }

    func testCalculateHarmonics_countNegative_returnsEmptyArray() {
        let harmonics = HarmonicCalculator.calculateHarmonics(f0: 100.0, count: -1)
        XCTAssertTrue(harmonics.isEmpty, "Should return an empty array if count is negative.")
    }

    func testCalculateHarmonics_defaultLabeling() {
        let f0: Double = 100.0
        // Test a harmonic number that doesn't have a special label
        let harmonics = HarmonicCalculator.calculateHarmonics(f0: f0, count: 9)
        XCTAssertEqual(harmonics[8].frequency, 900.0)
        XCTAssertEqual(harmonics[8].number, 9)
        XCTAssertEqual(harmonics[8].label, "9th Harmonic", "Label for 9th harmonic should be the default.")
    }
}

class UserF0ProfileTests: XCTestCase {

    func testUserF0Profile_calculatesHarmonicsOnInitialization() {
        let profile = UserF0Profile(value: 110.0) // A2
        XCTAssertNotNil(profile.harmonics, "Harmonics should be calculated on initialization if f0 is provided.")
        XCTAssertEqual(profile.harmonics?.count, 8, "Should calculate 8 harmonics by default.")
        XCTAssertEqual(profile.harmonics?.first?.frequency, 110.0, "Fundamental frequency should match the profile value.")
    }

    func testUserF0Profile_recalculatesHarmonicsWhenF0Changes() {
        var profile = UserF0Profile(value: 110.0)
        let initialHarmonicCount = profile.harmonics?.count

        profile.value = 220.0 // A3
        XCTAssertNotNil(profile.harmonics, "Harmonics should be recalculated when f0 changes.")
        XCTAssertEqual(profile.harmonics?.count, initialHarmonicCount, "Harmonic count should remain consistent after f0 change.")
        XCTAssertEqual(profile.harmonics?.first?.frequency, 220.0, "New fundamental frequency should be reflected in harmonics.")
        XCTAssertEqual(profile.harmonics?[1].frequency, 440.0, "Second harmonic should be double the new f0.")
    }

    func testUserF0Profile_clearsHarmonicsWhenF0IsNil() {
        var profile = UserF0Profile(value: 100.0)
        XCTAssertNotNil(profile.harmonics)

        profile.value = nil
        XCTAssertNil(profile.harmonics, "Harmonics should be nil if f0 is set to nil.")
    }

    func testUserF0Profile_initializesWithNilF0AndNilHarmonics() {
        let profile = UserF0Profile()
        XCTAssertNil(profile.value, "f0 should be nil initially.")
        XCTAssertNil(profile.harmonics, "Harmonics should be nil initially if f0 is nil.")
    }

    func testUserF0Profile_initializesWithExplicitHarmonics() {
        let customHarmonic = Harmonic(frequency: 150, label: "Custom", number: 1)
        let profile = UserF0Profile(value: 150.0, harmonics: [customHarmonic])
        XCTAssertEqual(profile.harmonics?.count, 1, "Should use explicitly provided harmonics.")
        XCTAssertEqual(profile.harmonics?.first?.label, "Custom")

        // Now change f0 and see if it recalculates based on the default logic
        profile.value = 200.0
        XCTAssertEqual(profile.harmonics?.count, 8, "Should recalculate to default number of harmonics when f0 changes.")
        XCTAssertEqual(profile.harmonics?.first?.frequency, 200.0)
        XCTAssertNotEqual(profile.harmonics?.first?.label, "Custom", "Label should be updated from 'Custom' after recalculation.")
    }
}
