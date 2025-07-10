import SwiftUI

struct CreateProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var profileName: String
    @Binding var selectedPitchId: UUID // Bound to ProfilesTabView's state

    // To access the globally defined pitchFrequencies
    private let availablePitches = pitchFrequencies

    // We need profileManager to add the profile
    @ObservedObject var profileManager: UserProfileManager

    var body: some View {
        NavigationView {
            Form {
                TextField("Profile Name", text: $profileName)
                Picker("Fundamental Frequency (f₀)", selection: $selectedPitchId) {
                    ForEach(availablePitches) { pitch in
                        Text("\(pitch.name) (\(pitch.frequency, specifier: "%.2f") Hz)").tag(pitch.id)
                    }
                }
            }
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if !profileName.isEmpty {
                            if let selectedPitch = availablePitches.first(where: { $0.id == selectedPitchId }) {
                                profileManager.addProfile(name: profileName, f0: selectedPitch.frequency)
                            } else if !availablePitches.isEmpty {
                                // Fallback: This should ideally not be reached if selectedPitchId is valid
                                profileManager.addProfile(name: profileName, f0: availablePitches[0].frequency)
                            }
                            // If availablePitches is empty, behavior depends on addProfile implementation for f0.
                        }
                        dismiss()
                    }
                    .disabled(profileName.isEmpty)
                }
            }
        }
    }
}
