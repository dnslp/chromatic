import SwiftUI

struct ProfilesTabView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var showingCreateProfileAlert = false
    @State private var newProfileName: String = ""
    @State private var newProfileF0: Double = 77.78
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
                        if let currentF0 = profileManager.currentProfile?.f0 {
                            newProfileF0 = currentF0
                        } else {
                            newProfileF0 = 77.78
                        }
                        showingCreateProfileAlert = true
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
            .alert("New Profile", isPresented: $showingCreateProfileAlert, actions: {
                TextField("Profile Name", text: $newProfileName)
                TextField("f₀ (Hz)", value: $newProfileF0, formatter: hzFormatter)
                    .keyboardType(.decimalPad)
                Button("Create") {
                    if !newProfileName.isEmpty {
                        profileManager.addProfile(name: newProfileName, f0: newProfileF0)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("Enter a name and fundamental frequency (f₀) for the new profile.")
            })
        }
    }

    private func deleteProfile(at offsets: IndexSet) {
        profileManager.deleteProfile(at: offsets)
    }

    private var hzFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

struct ProfilesTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilesTabView()
            .environmentObject(UserProfileManager())
    }
}
