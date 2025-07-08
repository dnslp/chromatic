import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager: UserProfileManager
    @State var editingProfile: UserProfile // A copy for editing

    private var originalProfile: UserProfile // To compare for changes or revert

    @Environment(\.presentationMode) var presentationMode

    init(profileManager: UserProfileManager, profile: UserProfile) {
        self.profileManager = profileManager
        self.originalProfile = profile
        self._editingProfile = State(initialValue: profile)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    HStack {
                        Text("Name:")
                        TextField("Profile Name", text: $editingProfile.name)
                    }

                    HStack {
                        Text("f₀ (Hz):")
                        TextField("Fundamental Frequency", value: $editingProfile.f0, formatter: hzFormatter)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Calculated Values")) {
                    HStack {
                        Text("Perfect Fourth:")
                        Spacer()
                        Text("\(editingProfile.perfectFourth, specifier: "%.2f") Hz")
                    }
                    HStack {
                        Text("Perfect Fifth:")
                        Spacer()
                        Text("\(editingProfile.perfectFifth, specifier: "%.2f") Hz")
                    }
                    HStack {
                        Text("Octave:")
                        Spacer()
                        Text("\(editingProfile.octave, specifier: "%.2f") Hz")
                    }
                }

                Section(header: Text("Harmonics (f₁ - f₇)")) {
                    ForEach(Array(editingProfile.harmonics.enumerated()), id: \.offset) { index, harmonicHz in
                        HStack {
                            Text("f\(index + 1):")
                            Spacer()
                            Text("\(harmonicHz, specifier: "%.2f") Hz")
                        }
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
