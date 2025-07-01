import XCTest
@testable import Chromatic

// Dummy pitch data for testing, mirroring what might be in the app
// In a real scenario, you might share the actual pitchFrequencies or use a mock.
// For simplicity here, we'll redefine a small subset.
let testPitchFrequencies: [Pitch] = [
    Pitch(name: "C4", frequency: 261.63),
    Pitch(name: "A4", frequency: 440.00),
    Pitch(name: "B4", frequency: 493.88)
]

// Make pitchFrequencies accessible for testing if it's not already global
// or provide a way to inject it. For this test, we'll assume the Channel
// class can be modified or uses a globally accessible pitchFrequencies constant
// that we can shadow or replace for testing.
// For now, let's assume the real `pitchFrequencies` is accessible.
// If not, the `Channel` class would need modification for testability (e.g., dependency injection).

class FunctionGeneratorEngineTests: XCTestCase {

    var audioFormat: AVAudioFormat!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Standard audio format for tests
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)

        // It's crucial that the Channel class uses a pitch list that we can control or inspect.
        // If pitchFrequencies is a global constant, these tests will use that.
        // If it's internal to the module and not accessible, Channel would need to be
        // made more testable, e.g. by injecting the pitch list.
        // For now, we proceed assuming `pitchFrequencies` (the app's actual one) is available.
    }

    override func tearDownWithError() throws {
        audioFormat = nil
        try super.tearDownWithError()
    }

    func testChannelInitialization() throws {
        let channel = Channel(format: audioFormat)
        let expectedPitch = pitchFrequencies.first { $0.name == "A4" }
        XCTAssertNotNil(expectedPitch, "A4 pitch should exist in test data.")

        XCTAssertEqual(channel.selectedPitch?.name, expectedPitch?.name, "Channel should initialize to A4.")
        XCTAssertEqual(channel.frequency, expectedPitch?.frequency, accuracy: 0.001, "Channel frequency should match A4's frequency.")
    }

    func testFrequencyToPitchUpdate_ExactMatch() throws {
        let channel = Channel(format: audioFormat)
        let targetPitch = pitchFrequencies.first { $0.name == "C4" }! // 261.63 Hz

        channel.frequency = 261.63
        XCTAssertEqual(channel.selectedPitch?.name, targetPitch.name)
        XCTAssertEqual(channel.frequency, targetPitch.frequency, accuracy: 0.001)
    }

    func testFrequencyToPitchUpdate_CloseMatch() throws {
        let channel = Channel(format: audioFormat)
        let targetPitch = pitchFrequencies.first { $0.name == "A4" }! // 440.00 Hz

        channel.frequency = 440.1 // Within 0.5 Hz tolerance
        XCTAssertEqual(channel.selectedPitch?.name, targetPitch.name)
        // Frequency itself should remain what it was set to, pitch is what's derived
        XCTAssertEqual(channel.frequency, 440.1, accuracy: 0.001)
    }

    func testFrequencyToPitchUpdate_AtToleranceEdgeLower() throws {
        let channel = Channel(format: audioFormat)
        let targetPitchA4 = pitchFrequencies.first { $0.name == "A4" }! // 440.00 Hz

        // A4 is 440.0. G#4/Ab4 is 415.30. B4 is 493.88
        // Testing A4 (440.00 Hz)
        // Lower edge of tolerance for A4: 440.0 - 0.499...
        channel.frequency = 439.51 // (440.0 - 0.49) -> should snap to A4
        XCTAssertEqual(channel.selectedPitch?.name, targetPitchA4.name, "Frequency 439.51 should map to A4")

        channel.frequency = 440.49 // (440.0 + 0.49) -> should snap to A4
        XCTAssertEqual(channel.selectedPitch?.name, targetPitchA4.name, "Frequency 440.49 should map to A4")
    }

    func testFrequencyToPitchUpdate_OutsideTolerance() throws {
        let channel = Channel(format: audioFormat)
        // A4 is 440.00 Hz. A#4/Bb4 is 466.16 Hz.
        // Midpoint is (440.00 + 466.16) / 2 = 453.08
        // A value like 450.0 should be far enough from both.
        // Tolerance is 0.5 Hz.
        // Closest to A4: 440.0. 450.0 is 10.0 away.
        // Closest to A#4/Bb4: 466.16. 450 is 16.16 away.
        channel.frequency = 450.0
        XCTAssertNil(channel.selectedPitch, "Frequency 450.0 Hz should not map to any pitch.")
        XCTAssertEqual(channel.frequency, 450.0, accuracy: 0.001)
    }

    func testFrequencyToPitchUpdate_SlightlyOutsideToleranceEdge() throws {
        let channel = Channel(format: audioFormat)
        // A4 is 440.00 Hz.
        // Test just outside the 0.5 Hz tolerance
        channel.frequency = 439.49 // (440.0 - 0.51) -> should be nil, or snap to G#4 if it's closer
                                  // G#4/Ab4 is 415.30. Distance is 24.19
                                  // So it should be nil.
        XCTAssertNil(channel.selectedPitch, "Frequency 439.49 should be nil (too far from A4, and G#4 is further).")

        channel.frequency = 440.51 // (440.0 + 0.51) -> should be nil, or snap to A#4 if it's closer
                                  // A#4/Bb4 is 466.16. Distance is 25.65
                                  // So it should be nil.
        XCTAssertNil(channel.selectedPitch, "Frequency 440.51 should be nil (too far from A4, and A#4 is further).")
    }

    func testPitchToFrequencyUpdate() throws {
        let channel = Channel(format: audioFormat)
        let targetPitchC4 = pitchFrequencies.first { $0.name == "C4" }!

        channel.selectedPitch = targetPitchC4
        XCTAssertEqual(channel.frequency, targetPitchC4.frequency, accuracy: 0.001)
        XCTAssertEqual(channel.selectedPitch?.name, targetPitchC4.name)
    }

    func testSetSelectedPitchToNil() throws {
        let channel = Channel(format: audioFormat)
        // Start with a known pitch
        let initialPitch = pitchFrequencies.first { $0.name == "A4" }!
        channel.selectedPitch = initialPitch
        XCTAssertEqual(channel.frequency, initialPitch.frequency, accuracy: 0.001)

        // Set selectedPitch to nil
        channel.selectedPitch = nil
        // Frequency should remain unchanged when selectedPitch is set to nil
        XCTAssertEqual(channel.frequency, initialPitch.frequency, accuracy: 0.001, "Frequency should not change when selectedPitch is set to nil.")
        XCTAssertNil(channel.selectedPitch)
    }

    func testNoRedundantFrequencyUpdateWhenPitchIsSetToSameValue() throws {
        let channel = Channel(format: audioFormat)
        let pitchA4 = pitchFrequencies.first { $0.name == "A4" }!
        channel.selectedPitch = pitchA4 // Initial set

        // Mock observing frequency changes (not directly possible without KVO or Combine publisher)
        // Instead, we check if the frequency is still the same and selectedPitch is still the same.
        // The `didSet` for `selectedPitch` has guards: `oldValue?.name != newPitch.name` and `abs(newPitch.frequency - frequency) > 0.001`
        let initialFrequency = channel.frequency

        channel.selectedPitch = pitchA4 // Set to same value

        XCTAssertEqual(channel.frequency, initialFrequency, accuracy: 0.001, "Frequency should not change if pitch is set to its current value.")
        XCTAssertEqual(channel.selectedPitch?.name, pitchA4.name)
    }

    func testNoRedundantPitchUpdateWhenFrequencyResultsInSamePitch() throws {
        let channel = Channel(format: audioFormat)
        let pitchA4 = pitchFrequencies.first { $0.name == "A4" }! // 440.0 Hz

        channel.frequency = 440.0 // This will set selectedPitch to A4
        XCTAssertEqual(channel.selectedPitch?.name, pitchA4.name)

        // Now, set frequency to something else that still maps to A4
        // The `didSet` for `frequency` has a guard: `selectedPitch?.name != matchedPitch.name`
        channel.frequency = 440.1
        XCTAssertEqual(channel.selectedPitch?.name, pitchA4.name, "Selected pitch should still be A4.")
        XCTAssertEqual(channel.frequency, 440.1, accuracy: 0.001)

        // And if it's already nil, and new frequency also results in nil
        channel.frequency = 450.0 // Should set selectedPitch to nil
        XCTAssertNil(channel.selectedPitch)
        channel.frequency = 450.1 // Should still result in nil
        XCTAssertNil(channel.selectedPitch)
         XCTAssertEqual(channel.frequency, 450.1, accuracy: 0.001)
    }
}
