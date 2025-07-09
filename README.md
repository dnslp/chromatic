
# chromatic

This project defines a global constant `pitchFrequencies` containing the
equal-tempered tuning table.  Previews and unit tests rely on this constant to
look up pitch information.  It is declared `public` in
`Chromatic/Models/Pitch.swift` so external contexts can reference it directly or
replace it with test data when needed.
=======
# Chromatic

Chromatic is a cross-platform pitch tuner and practice tool written in SwiftUI. It features real‑time pitch detection, color‑coded feedback for accuracy, harmonic visualizations and the ability to record sessions for later analysis. A simple audio player is included so you can practice along with your own recordings.

## Building the App

1. Install **Xcode 15** or newer.
2. Clone this repository and open `Chromatic.xcodeproj` in Xcode.
3. Select the `Chromatic` scheme for your desired platform (iOS, macOS or watchOS).
4. Choose a simulator or a connected device and run the project using `Run` (\u2318R) or via `xcodebuild`:
   ```sh
   xcodebuild -scheme Chromatic -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

## Running Tests

To execute the unit and UI tests, including the snapshot tests, run:

```sh
xcodebuild test -scheme Chromatic -destination 'platform=iOS Simulator,name=iPhone 15'
```

Snapshot reference images are stored under `ChromaticTests/__Snapshots__` and `Packages/MicrophonePitchDetector/Tests`. To update these snapshots set `RECORD_SNAPSHOTS=1` in the environment when running the tests:

```sh
RECORD_SNAPSHOTS=1 xcodebuild test -scheme Chromatic -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository and create a topic branch.
2. Make your changes and ensure `xcodebuild test` succeeds.
3. Submit a pull request describing your changes.


