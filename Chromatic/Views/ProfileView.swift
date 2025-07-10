import SwiftUI

// MARK: - Helper Structs for Cached Data
struct HarmonicDisplayInfo: Identifiable {
    let id = UUID()
    let originalIndex: Int
    let frequency: Double
    let note: String
    let cents: Int
    let color: Color
}

struct ModeDegreeInfo: Identifiable {
    let id = UUID() // Using UUID for simplicity, could use degree string if unique
    let degree: String
    let note: String
    let freq: Double
    let cents: Int
}

struct ProfileDataCache {
    var f0Display: (note: String, cents: Int) = ("–", 0)
    var p4Display: (note: String, cents: Int) = ("–", 0)
    var p5Display: (note: String, cents: Int) = ("–", 0)
    var octaveDisplay: (note: String, cents: Int) = ("–", 0)
    var harmonicDisplayInfos: [HarmonicDisplayInfo] = []
    var scaleDegreesForModes: [String: [ModeDegreeInfo]] = [:]
}

struct ProfileView: View {
    @ObservedObject var profileManager: UserProfileManager
    @State var editingProfile: UserProfile // A copy for editing
    @StateObject private var tonePlayer = TonePlayer()
    @StateObject private var cacheUpdater: ProfileCacheUpdater // Handles cache updates

    @State private var expandedModes: Set<String> = ["Ionian (Major)"] // default expanded
    @State private var dataCache: ProfileDataCache = ProfileDataCache()

    private var originalProfile: UserProfile // To compare for changes or revert

    @Environment(\.presentationMode) var presentationMode

    init(profileManager: UserProfileManager, profile: UserProfile) {
        self.profileManager = profileManager
        self.originalProfile = profile
        self._editingProfile = State(initialValue: profile)
        self._cacheUpdater = StateObject(wrappedValue: ProfileCacheUpdater(profile: profile))
    }

    // Keep static constants and pure calculation functions
    private static let chakraFrequencies: [Double] = [396, 417, 528, 639, 741, 852, 963]
    private static let chakraColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple
    ]

    // MARK: - Static Calculation Helpers (moved to ProfileCacheUpdater or kept static if general)
    // These functions are used by ProfileCacheUpdater now.
    // For simplicity in this diff, I'm leaving them static here if they don't need instance data
    // but they could also be part of the updater or a separate utility.

    static func chakraColor(for freq: Double) -> Color {
        let idx = chakraFrequencies
            .enumerated()
            .min(by: { abs($0.element - freq) < abs($1.element - freq) })!
            .offset
        return chakraColors[idx]
    }
    
    static func noteNameAndCents(for frequency: Double) -> (String, Int) {
        guard frequency > 0 else { return ("–", 0) }
        let noteNames = ProfileView.noteNames // Assuming noteNames remains static here
        
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

    static let noteNames: [String] = [
        "C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"
    ]

    static let majorScaleIntervals: [Int] = [0, 2, 4, 5, 7, 9, 11, 12]
    
    static let modeIntervals: [(name: String, intervals: [Int])] = [
        ("Ionian (Major)",     [0, 2, 4, 5, 7, 9, 11, 12]),
        ("Dorian",             [0, 2, 3, 5, 7, 9, 10, 12]),
        ("Phrygian",           [0, 1, 3, 5, 7, 8, 10, 12]),
        ("Lydian",             [0, 2, 4, 6, 7, 9, 11, 12]),
        ("Mixolydian",         [0, 2, 4, 5, 7, 9, 10, 12]),
        ("Aeolian (Minor)",    [0, 2, 3, 5, 7, 8, 10, 12]),
        ("Locrian",            [0, 1, 3, 5, 6, 8, 10, 12]),
    ]

    static func scaleDegrees(for rootHz: Double, intervals: [Int]) -> [(degree: String, note: String, freq: Double, cents: Int)] {
        let noteNames = ProfileView.noteNames // Assuming noteNames remains static here
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

    // This overload might not be strictly necessary if the default major scale intervals are passed explicitly
    // but kept for consistency if it was used elsewhere or for clarity.
    static func scaleDegrees(for rootHz: Double) -> [(degree: String, note: String, freq: Double, cents: Int)] {
        let noteNames = ProfileView.noteNames // Assuming noteNames remains static here
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
                            Text("\(dataCache.f0Display.note) (\(dataCache.f0Display.cents >= 0 ? "+" : "")\(dataCache.f0Display.cents)¢)")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                    }
                }

                Section(header: Text("Calculated Values")) {
                    Button(action: { tonePlayer.play(frequency: editingProfile.perfectFourth) }) {
                        HStack {
                            Text("Perfect Fourth:")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(editingProfile.perfectFourth, specifier: "%.2f") Hz")
                                Text("\(dataCache.p4Display.note) (\(dataCache.p4Display.cents >= 0 ? "+" : "")\(dataCache.p4Display.cents)¢)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Image(systemName: "play.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { tonePlayer.play(frequency: editingProfile.perfectFifth) }) {
                        HStack {
                            Text("Perfect Fifth:")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(editingProfile.perfectFifth, specifier: "%.2f") Hz")
                                Text("\(dataCache.p5Display.note) (\(dataCache.p5Display.cents >= 0 ? "+" : "")\(dataCache.p5Display.cents)¢)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Image(systemName: "play.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { tonePlayer.play(frequency: editingProfile.octave) }) {
                        HStack {
                            Text("Octave:")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(editingProfile.octave, specifier: "%.2f") Hz")
                                Text("\(dataCache.octaveDisplay.note) (\(dataCache.octaveDisplay.cents >= 0 ? "+" : "")\(dataCache.octaveDisplay.cents)¢)")
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
                    ForEach(dataCache.harmonicDisplayInfos) { info in
                        Button(action: { tonePlayer.play(frequency: info.frequency) }) {
                            HStack {
                                Circle()
                                    .fill(info.color)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                    )
                                Text("f\(info.originalIndex + 1):")
                                Spacer()
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("\(info.frequency, specifier: "%.2f") Hz")
                                    Text("\(info.note) (\(info.cents >= 0 ? "+" : "")\(info.cents)¢)")
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
                                if let degrees = dataCache.scaleDegreesForModes[mode.name] {
                                    ForEach(degrees) { degreeInfo in
                                        Button(action: { tonePlayer.play(frequency: degreeInfo.freq) }) {
                                            HStack {
                                                Text("Degree \(degreeInfo.degree):")
                                                Spacer()
                                                VStack(alignment: .trailing) {
                                                    Text("\(degreeInfo.note)  \(degreeInfo.freq, specifier: "%.2f") Hz")
                                                    Text("\(degreeInfo.cents >= 0 ? "+" : "")\(degreeInfo.cents)¢")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                Image(systemName: "play.circle")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } else {
                                    Text("Loading mode data...") // Should be quick
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
                        // Pass the potentially modified editingProfile
                        profileManager.updateProfile(cacheUpdater.currentProfile)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isProfileChanged()) // isProfileChanged still uses originalProfile and editingProfile state
                }
            }
        }
        // Use the cacheUpdater's published cache
        .onReceive(cacheUpdater.$cache) { newCache in
            self.dataCache = newCache
        }
        // Trigger updates in the updater when editingProfile.f0 changes
        .onChange(of: editingProfile.f0) { newF0 in
            // Update the profile within the updater, which will trigger cache recalculation
            var updatedProfile = editingProfile
            updatedProfile.f0 = newF0 // Ensure the f0 is set before passing
            cacheUpdater.updateProfile(updatedProfile)
        }
        // Ensure F0SelectorView updates editingProfile.f0, which then triggers above .onChange
    }

    private func isProfileChanged() -> Bool {
        // Compare the current f0 in editingProfile with the original
        // Or, if cacheUpdater.currentProfile is always the source of truth for "editing":
        return editingProfile.name != originalProfile.name || cacheUpdater.currentProfile.f0 != originalProfile.f0
    }

    // hzFormatter might not be needed if all formatting is done via Text initializers
    // For now, keeping it if it's used by F0SelectorView or other parts not shown.
    private var hzFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

// MARK: - ObservableObject for Cache Updates
// This class will own the logic for updating the cache when the profile changes.
class ProfileCacheUpdater: ObservableObject {
    @Published var cache: ProfileDataCache
    @Published var currentProfile: UserProfile

    init(profile: UserProfile) {
        self.currentProfile = profile
        self.cache = ProfileCacheUpdater.calculateCache(for: profile)
    }

    func updateProfile(_ newProfile: UserProfile) {
        self.currentProfile = newProfile
        self.cache = ProfileCacheUpdater.calculateCache(for: newProfile)
    }

    static func calculateCache(for profile: UserProfile) -> ProfileDataCache {
        let f0Display = ProfileView.noteNameAndCents(for: profile.f0)
        let p4Display = ProfileView.noteNameAndCents(for: profile.perfectFourth)
        let p5Display = ProfileView.noteNameAndCents(for: profile.perfectFifth)
        let octaveDisplay = ProfileView.noteNameAndCents(for: profile.octave)

        let harmonicInfos = profile.harmonics.enumerated().map { index, harmonicHz -> HarmonicDisplayInfo in
            let noteCents = ProfileView.noteNameAndCents(for: harmonicHz)
            let color = ProfileView.chakraColor(for: harmonicHz)
            return HarmonicDisplayInfo(
                originalIndex: index,
                frequency: harmonicHz,
                note: noteCents.0,
                cents: noteCents.1,
                color: color
            )
        }

        var modeDegrees: [String: [ModeDegreeInfo]] = [:]
        for mode in ProfileView.modeIntervals {
            let degreesData = ProfileView.scaleDegrees(for: profile.f0, intervals: mode.intervals)
            modeDegrees[mode.name] = degreesData.map { dataTuple -> ModeDegreeInfo in
                ModeDegreeInfo(degree: dataTuple.degree, note: dataTuple.note, freq: dataTuple.freq, cents: dataTuple.cents)
            }
        }

        return ProfileDataCache(
            f0Display: f0Display,
            p4Display: p4Display,
            p5Display: p5Display,
            octaveDisplay: octaveDisplay,
            harmonicDisplayInfos: harmonicInfos,
            scaleDegreesForModes: modeDegrees
        )
    }
}


// Preview Provider might need adjustment if ProfileCacheUpdater init changes
// For now, assuming it works or will be adjusted if UserProfile init changes.

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        let manager = UserProfileManager()
//        if manager.profiles.isEmpty {
//            let sampleProfile = UserProfile(
//                id: UUID(),
//                name: "Preview Profile",
//                f0: 440.0
//                // harmonics are computed, so not needed in init directly for this example
//            )
//            manager.addProfile(userProfile: sampleProfile) // Assuming addProfile takes UserProfile
//        }
//        let profileToPreview = manager.profiles.first!
//        return ProfileView(profileManager: manager, profile: profileToPreview)
//            .preferredColorScheme(.dark)
//    }
//}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = UserProfileManager()
        if manager.profiles.isEmpty {
            // Ensure UserProfile can be created with f0 for preview
            manager.addProfile(name: "Preview Profile", f0: 220.0)
        }
        let sampleProfile = manager.profiles.first!
        return ProfileView(profileManager: manager, profile: sampleProfile)
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}
