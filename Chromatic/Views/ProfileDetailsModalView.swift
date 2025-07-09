import SwiftUI

struct ProfileDetailsModalView: View {
    // We'll need to pass in the UserProfile to display its stats
    let profile: UserProfile

    // Environment variable to dismiss the modal
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                Text("Details for \(profile.name)")
                    .font(.title)
                    .padding()

                List {
                    Section(header: Text("Fundamental Frequency")) {
                        Text("f₀: \(profile.f0, specifier: "%.2f") Hz")
                    }

                    Section(header: Text("Calculated Intervals")) {
                        Text("Perfect Fourth: \(profile.perfectFourth, specifier: "%.2f") Hz")
                        Text("Perfect Fifth: \(profile.perfectFifth, specifier: "%.2f") Hz")
                        Text("Octave: \(profile.octave, specifier: "%.2f") Hz")
                    }

                    Section(header: Text("Harmonics (f₁ - f₇)")) {
                        // Assuming UserProfile has a harmonics array
                        // If UserProfile.harmonics is not directly an array of Doubles, this will need adjustment
                        ForEach(Array(profile.harmonics.enumerated()), id: \.offset) { index, harmonicHz in
                            Text("f\(index + 1): \(harmonicHz, specifier: "%.2f") Hz")
                        }
                    }
                }

                Spacer()

                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
            .navigationTitle("Profile Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ProfileDetailsModalView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample UserProfile for the preview
        let sampleProfile = UserProfile(
            id: UUID(),
            name: "Sample Profile",
            f0: 440.0 // A4
            // harmonics are automatically calculated by UserProfile
        )
        ProfileDetailsModalView(profile: sampleProfile)
    }
}
