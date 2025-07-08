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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    HStack {
                        Text("Name:")
                        TextField("Profile Name", text: $editingProfile.name)
                    }
                    
                    
                    Button(action: { tonePlayer.play(frequency: editingProfile.f0) }) {
                        HStack {
                            Text("f₀ (Hz):")
                            Spacer()
                            Text("\(editingProfile.f0, specifier: "%.2f") Hz")
                            Image(systemName: "play.circle")
                                .foregroundColor(.accentColor)
                        }
                        }
                }

                Section(header: Text("Calculated Values")) {
                Button(action: { tonePlayer.play(frequency: editingProfile.perfectFourth) }) {
                    HStack {
                        Text("Perfect Fourth:")
                        Spacer()
                        Text("\(editingProfile.perfectFourth, specifier: "%.2f") Hz")
                        Image(systemName: "play.circle")
                            .foregroundColor(.accentColor)
                    }
                    }
                .buttonStyle(.plain)

                Button(action: { tonePlayer.play(frequency: editingProfile.perfectFifth) }) {
                    HStack {
                        Text("Perfect Fifth:")
                        Spacer()
                        Text("\(editingProfile.perfectFifth, specifier: "%.2f") Hz")
                        Image(systemName: "play.circle")
                            .foregroundColor(.accentColor)
                    }
                    }
                .buttonStyle(.plain)

                Button(action: { tonePlayer.play(frequency: editingProfile.octave) }) {
                    HStack {
                        Text("Octave:")
                        Spacer()
                        Text("\(editingProfile.octave, specifier: "%.2f") Hz")
                        Image(systemName: "play.circle")
                            .foregroundColor(.accentColor)
                    }
                    }
                .buttonStyle(.plain)
                }

                Section(header: Text("Harmonics (f₁ - f₇)")) {
                    ForEach(Array(editingProfile.harmonics.enumerated()), id: \.offset) { index, harmonicHz in
                        Button(action: { tonePlayer.play(frequency: harmonicHz) }) {
                            HStack {
                                // Chakra color indicator
                                Circle()
                                    .fill(chakraColor(for: harmonicHz))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                    )
                                
                                Text("f\(index + 1):")
                                Spacer()
                                Text("\(harmonicHz, specifier: "%.2f") Hz")
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample profile and manager for previewing
        let manager = UserProfileManager()
        // Ensure there's at least one profile for the preview, e.g., the default
        if manager.profiles.isEmpty {
            manager.addProfile(name: "Preview Profile", f0: 440.0)
        }
        let profileToPreview = manager.profiles.first ?? UserProfile.defaultProfile()

        return ProfileView(profileManager: manager, profile: profileToPreview)
    }
}
