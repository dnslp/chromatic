import SwiftUI

struct ProfilesTabView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var showingCreateProfileSheet = false // Changed from showingCreateProfileAlert
    @State private var newProfileName: String = ""
    // newProfileF0 is still used to initialize the picker's selection indirectly via selectedPitchId
    // and potentially by EditProfileSheet if it expects an f0.
    @State private var newProfileF0: Double = 77.78
    @State private var selectedPitchId: UUID = pitchFrequencies.first(where: { $0.name == "D#2/Eb2" })?.id ?? pitchFrequencies.first?.id ?? UUID()
    @State private var profileToEdit: UserProfile? = nil
    @State private var selectedProfile: UserProfile? = nil // For showing full profile page

    struct EditProfileSheet: View {
        @Environment(\.dismiss) var dismiss
        @State var name: String
        @State var f0: Double
        let onSave: (String, Double) -> Void

        init(initialName: String, initialF0: Double, onSave: @escaping (String, Double) -> Void) {
            _name = State(initialValue: initialName)
            _f0 = State(initialValue: initialF0)
            self.onSave = onSave
        }

        var body: some View {
            NavigationView {
                Form {
                    TextField("Profile Name", text: $name)
                    TextField("f₀ (Hz)", value: $f0, formatter: hzFormatter)
                        .keyboardType(.decimalPad)
                }
                .navigationTitle("Edit Profile")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if !name.isEmpty {
                                onSave(name, f0)
                            }
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }

        private var hzFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            return formatter
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(profileManager.profiles) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .font(.headline)
                            Text("f₀: \(profile.f0, specifier: "%.2f") Hz")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button {
                            profileToEdit = profile
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProfile = profile
                    }
                }
                .onDelete(perform: deleteProfile)
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newProfileName = ""
                        // Attempt to find a pitch matching the current profile's f0 or default to D#2/Eb2
                        if let currentF0 = profileManager.currentProfile?.f0,
                           let matchingPitch = pitchFrequencies.first(where: { abs($0.frequency - currentF0) < 0.01 }) {
                            selectedPitchId = matchingPitch.id
                            newProfileF0 = matchingPitch.frequency
                        } else {
                            // Default to D#2/Eb2 if no current profile or no matching pitch
                            let defaultPitch = pitchFrequencies.first(where: { $0.name == "D#2/Eb2" }) ?? pitchFrequencies.first!
                            selectedPitchId = defaultPitch.id
                            newProfileF0 = defaultPitch.frequency // Keep newProfileF0 for initial consistency if needed elsewhere
                        }
                        showingCreateProfileSheet = true // Present the sheet
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            // Edit Profile Sheet
            .sheet(item: $profileToEdit) { selectedProfile in
                EditProfileSheet(
                    initialName: selectedProfile.name,
                    initialF0: selectedProfile.f0
                ) { newName, newF0 in
                    profileManager.updateProfile(id: selectedProfile.id, name: newName, f0: newF0)
                }
            }
            // Full Profile Page Sheet
            .sheet(item: $selectedProfile) { profile in
                ProfileView(profileManager: profileManager, profile: profile)
            }
            // Sheet for creating a new profile
            .sheet(isPresented: $showingCreateProfileSheet) {
                CreateProfileSheet(
                    profileName: $newProfileName,
                    selectedPitchId: $selectedPitchId,
                    profileManager: profileManager
                )
            }
            // Removed the .alert for new profile creation
        }
    }

    private func deleteProfile(at offsets: IndexSet) {
        profileManager.deleteProfile(at: offsets)
    }

    // hzFormatter is no longer needed here as the Picker handles formatting.
    // If it's used elsewhere, it can remain, otherwise it can be removed.
    // For now, I will leave it commented out in case it's used by EditProfileSheet or other parts.
    /*
    private var hzFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
    */
}

struct ProfilesTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilesTabView()
            .environmentObject(UserProfileManager())
    }
}
