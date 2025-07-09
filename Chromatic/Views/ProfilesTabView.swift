import SwiftUI

struct ProfilesTabView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var showingCreateProfileAlert = false
    @State private var newProfileName: String = ""
    @State private var newProfileF0: Double = 77.78
    @State private var profileToEdit: UserProfile? = nil

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
                        profileManager.selectProfile(profile)
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
            .sheet(item: $profileToEdit) { selectedProfile in
                ProfileView(profileManager: profileManager, profile: selectedProfile)
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
