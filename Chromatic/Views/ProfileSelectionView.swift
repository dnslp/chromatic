import SwiftUI

struct ProfileSelectionView: View {
    @ObservedObject var profileManager: UserProfileManager
    @Binding var isPresented: Bool // To dismiss the sheet

    @State private var showingCreateProfileAlert = false
    @State private var newProfileName: String = ""
    @State private var newProfileF0: Double = 77.78 // Default f0, can be adjusted

    // For navigating to the detail/edit view
    @State private var profileToEdit: UserProfile? = nil
    @State private var showingEditSheet = false

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
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle()) // To ensure button works in a list row
                    }
                    .contentShape(Rectangle()) // Make the whole row tappable for selection
                    .onTapGesture {
                        profileManager.selectProfile(profile)
                        isPresented = false // Dismiss this selection view
                    }
                }
                .onDelete(perform: deleteProfile)
            }
            .navigationTitle("Select Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Reset for new profile entry
                        newProfileName = ""
                        // Optionally, prefill f0 with the current f0 from TunerView if accessible
                        // For now, using a common default or last used.
                        if let currentF0 = profileManager.currentProfile?.f0 {
                            newProfileF0 = currentF0
                        } else {
                            newProfileF0 = 77.78 // A sensible default
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
            .sheet(isPresented: $showingEditSheet) {
                if let profile = profileToEdit {
                    // Pass the original profile for editing
                    ProfileView(profileManager: profileManager, profile: profile)
                }
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
        // Need to handle how currentProfile is affected if it's deleted.
        // UserProfileManager's deleteProfile(at:) should handle this.
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

struct ProfileSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = UserProfileManager()
        // Add a few profiles for preview
        if manager.profiles.isEmpty { // Ensure default is there
             manager.addProfile(name: "Violin G3", f0: 196.00)
             manager.addProfile(name: "Guitar E2", f0: 82.41)
        }
       

        return ProfileSelectionView(profileManager: manager, isPresented: .constant(true))
    }
}
