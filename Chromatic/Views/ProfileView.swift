import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager: UserProfileManager
    @State var editingProfile: UserProfile // A copy for editing
    @StateObject private var tonePlayer = TonePlayer()
    
    @State private var expandedModes: Set<String> = ["Ionian (Major)"] // default expanded


    private var originalProfile: UserProfile // To compare for changes or revert

    @Environment(\.presentationMode) var presentationMode

    init(profileManager: UserProfileManager, profile: UserProfile) {
        self.profileManager = profileManager
        self.originalProfile = profile
        self._editingProfile = State(initialValue: profile)
    }

    private let chakraFrequencies: [Double] = [396, 417, 528, 639, 741, 852, 963]
    private let chakraColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple
    ]

    private func chakraColor(for freq: Double) -> Color {
        let idx = chakraFrequencies
            .enumerated()
            .min(by: { abs($0.element - freq) < abs($1.element - freq) })!
            .offset
        return chakraColors[idx]
    }
    
    /// Returns (note name with octave, cents offset)
    private func noteNameAndCents(for frequency: Double) -> (String, Int) {
        guard frequency > 0 else { return ("–", 0) }
        // Move noteNames out to a static property to help typechecker
        let noteNames = ProfileView.noteNames
        
        let freqRatio = frequency / 440.0
        let midiDouble = 69.0 + 12.0 * log2(freqRatio)
        let midi = Int(round(midiDouble))
        let noteIndex = (midi + 120) % 12
        let noteName = noteNames[noteIndex]
        let noteHz = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
        let centsDouble = 1200.0 * log2(frequency / noteHz)
        let cents = Int(round(centsDouble))
        let octave = (midi / 12) - 1
        return ("\(noteName)\(octave)", cents)
    }

    private static let noteNames: [String] = [
        "C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"
    ]

    // Define major scale intervals in semitones
    private static let majorScaleIntervals: [Int] = [0, 2, 4, 5, 7, 9, 11, 12]
    
    // Each mode is defined by semitone intervals from the root (degrees 1–7, then octave)
    private static let modeIntervals: [(name: String, intervals: [Int])] = [
        ("Ionian (Major)",     [0, 2, 4, 5, 7, 9, 11, 12]),
        ("Dorian",             [0, 2, 3, 5, 7, 9, 10, 12]),
        ("Phrygian",           [0, 1, 3, 5, 7, 8, 10, 12]),
        ("Lydian",             [0, 2, 4, 6, 7, 9, 11, 12]),
        ("Mixolydian",         [0, 2, 4, 5, 7, 9, 10, 12]),
        ("Aeolian (Minor)",    [0, 2, 3, 5, 7, 8, 10, 12]),
        ("Locrian",            [0, 1, 3, 5, 6, 8, 10, 12]),
    ]
    private func scaleDegrees(for rootHz: Double, intervals: [Int]) -> [(degree: String, note: String, freq: Double, cents: Int)] {
        let noteNames = ProfileView.noteNames
        let rootFreqRatio = rootHz / 440.0
        let rootMidi = 69.0 + 12.0 * log2(rootFreqRatio)
        return intervals.enumerated().map { (i, interval) in
            let midi = Int(round(rootMidi)) + interval
            let freq = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
            let noteIndex = (midi + 120) % 12
            let octave = (midi / 12) - 1
            let noteName = noteNames[noteIndex]
            let cents = Int(round(1200.0 * log2(freq / (rootHz * pow(2.0, Double(interval) / 12.0)))))
            return ("\(i+1)", "\(noteName)\(octave)", freq, cents)
        }
    }

    // Return scale notes and their info given a starting frequency
    private func scaleDegrees(for rootHz: Double) -> [(degree: String, note: String, freq: Double, cents: Int)] {
        let noteNames = ProfileView.noteNames
        let rootFreqRatio = rootHz / 440.0
        let rootMidi = 69.0 + 12.0 * log2(rootFreqRatio)
        return ProfileView.majorScaleIntervals.enumerated().map { (i, interval) in
            let midi = Int(round(rootMidi)) + interval
            let freq = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
            let noteIndex = (midi + 120) % 12
            let octave = (midi / 12) - 1
            let noteName = noteNames[noteIndex]
            let cents = Int(round(1200.0 * log2(freq / (rootHz * pow(2.0, Double(interval) / 12.0)))))
            return ("\(i+1)", "\(noteName)\(octave)", freq, cents)
        }
    }

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    HStack {
                        Text("Name:")
                        Text(editingProfile.name)
                            .foregroundColor(.primary)
                    }
                    let (f0Note, f0Cents) = noteNameAndCents(for: editingProfile.f0)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("f₀ (Hz):")
                            F0SelectorView(f0Hz: $editingProfile.f0)
                            Spacer()
                            Button(action: { tonePlayer.play(frequency: editingProfile.f0) }) {
                                Image(systemName: "play.circle")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        HStack {
                            Spacer()
                            Text("\(f0Note) (\(f0Cents >= 0 ? "+" : "")\(f0Cents)¢)")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                    }
                }

                Section(header: Text("Calculated Values")) {
                    let (p4Note, p4Cents) = noteNameAndCents(for: editingProfile.perfectFourth)
                    Button(action: { tonePlayer.play(frequency: editingProfile.perfectFourth) }) {
                        HStack {
                            Text("Perfect Fourth:")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(editingProfile.perfectFourth, specifier: "%.2f") Hz")
                                Text("\(p4Note) (\(p4Cents >= 0 ? "+" : "")\(p4Cents)¢)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Image(systemName: "play.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)

                    let (p5Note, p5Cents) = noteNameAndCents(for: editingProfile.perfectFifth)
                    Button(action: { tonePlayer.play(frequency: editingProfile.perfectFifth) }) {
                        HStack {
                            Text("Perfect Fifth:")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(editingProfile.perfectFifth, specifier: "%.2f") Hz")
                                Text("\(p5Note) (\(p5Cents >= 0 ? "+" : "")\(p5Cents)¢)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Image(systemName: "play.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)

                    let (octNote, octCents) = noteNameAndCents(for: editingProfile.octave)
                    Button(action: { tonePlayer.play(frequency: editingProfile.octave) }) {
                        HStack {
                            Text("Octave:")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(editingProfile.octave, specifier: "%.2f") Hz")
                                Text("\(octNote) (\(octCents >= 0 ? "+" : "")\(octCents)¢)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Image(systemName: "play.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section(header: Text("Harmonics (f₁ - f₇)")) {
                    ForEach(Array(editingProfile.harmonics.enumerated()), id: \.offset) { index, harmonicHz in
                        // Calculate outside the view builder!
                        let noteCents = noteNameAndCents(for: harmonicHz)
                        Button(action: { tonePlayer.play(frequency: harmonicHz) }) {
                            HStack {
                                Circle()
                                    .fill(chakraColor(for: harmonicHz))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                    )
                                Text("f\(index + 1):")
                                Spacer()
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("\(harmonicHz, specifier: "%.2f") Hz")
                                    Text("\(noteCents.0) (\(noteCents.1 >= 0 ? "+" : "")\(noteCents.1)¢)")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                                Image(systemName: "play.circle")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ProfileView.modeIntervals, id: \.name) { mode in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedModes.contains(mode.name) },
                                set: { expanded in
                                    if expanded {
                                        expandedModes.insert(mode.name)
                                    } else {
                                        expandedModes.remove(mode.name)
                                    }
                                }
                            ),
                            content: {
                                let degrees = scaleDegrees(for: editingProfile.f0, intervals: mode.intervals)
                                ForEach(degrees, id: \.degree) { degree, note, freq, cents in
                                    Button(action: { tonePlayer.play(frequency: freq) }) {
                                        HStack {
                                            Text("Degree \(degree):")
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                Text("\(note)  \(freq, specifier: "%.2f") Hz")
                                                Text("\(cents >= 0 ? "+" : "")\(cents)¢")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Image(systemName: "play.circle")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            },
                            label: {
                                Text("\(mode.name)")
                                    .font(.headline)
                            }
                        )
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top)

            }
            .navigationTitle("Profile Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        profileManager.updateProfile(editingProfile)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isProfileChanged())
                }
            }
        }
    }

    private func isProfileChanged() -> Bool {
        return editingProfile.name != originalProfile.name || editingProfile.f0 != originalProfile.f0
    }

    private var hzFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        let manager = UserProfileManager()
//        if manager.profiles.isEmpty {
//            let sampleProfile = UserProfile(
//                id: UUID(),
//                name: "Preview Profile",
//                f0: 440.0,
//                harmonics: (1...7).map { Double($0) * 440.0 }
//            )
//            manager.profiles = [sampleProfile]
//        }
//        let profileToPreview = manager.profiles.first!
//        return ProfileView(profileManager: manager, profile: profileToPreview)
//            .preferredColorScheme(.dark)
//    }
//}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Make a temporary manager with at least one profile.
        let manager = UserProfileManager()
        // Force at least one profile for preview (does nothing if already exists)
        if manager.profiles.isEmpty {
            manager.addProfile(name: "Preview Profile", f0: 220.0)
        }
        // Pick the first profile (always exists due to above)
        let sampleProfile = manager.profiles.first!
        return ProfileView(profileManager: manager, profile: sampleProfile)
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}
