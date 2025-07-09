import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager: UserProfileManager
    @State var editingProfile: UserProfile // A copy for editing
    @StateObject private var tonePlayer = TonePlayer()

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
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
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

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    HStack {
                        Text("Name:")
                        TextField("Profile Name", text: $editingProfile.name)
                    }
                    let (f0Note, f0Cents) = noteNameAndCents(for: editingProfile.f0)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
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
        // Create a UserProfileManager instance for the preview
        let manager = UserProfileManager()

        // Ensure there's at least one profile to preview.
        // If the manager initializes with a default profile, this might not be strictly necessary,
        // but it's good for ensuring the preview always has data.
        if manager.profiles.isEmpty {
            manager.addProfile(name: "Preview Profile", f0: 440.0)
        }

        // Select the first profile for the preview, or a default if none (though the above ensures one)
        let profileToPreview = manager.profiles.first ?? UserProfile(id: UUID(), name: "Default Preview", f0: 261.63) // C4 as fallback

        return ProfileView(profileManager: manager, profile: profileToPreview)
            .preferredColorScheme(.dark)
    }
}
