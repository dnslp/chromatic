import Foundation
import SwiftUI // For ObservableObject, @Published

class UserProfileManager: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var currentProfile: UserProfile?

    private var documentsUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private var profilesFileURL: URL? {
        documentsUrl?.appendingPathComponent("user_profiles.json")
    }

    init() {
        loadProfiles()
        if profiles.isEmpty {
            let defaultProfile = UserProfile.defaultProfile()
            profiles.append(defaultProfile)
            currentProfile = defaultProfile
            saveProfiles() // Save the default if no profiles existed
        } else if currentProfile == nil {
            currentProfile = profiles.first // Select the first profile if none is current
        }
    }

    // MARK: - Storage
    func saveProfiles() {
        guard let fileURL = profilesFileURL else {
            print("Error: Could not get profiles file URL.")
            return
        }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profiles)
            try data.write(to: fileURL, options: .atomicWrite)
            print("Profiles saved to \(fileURL.path)")
        } catch {
            print("Error saving profiles: \(error.localizedDescription)")
        }
    }

    func loadProfiles() {
        guard let fileURL = profilesFileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Info: Profiles file does not exist or URL is invalid. Starting with defaults.")
            self.profiles = [] // Ensure profiles is empty if file doesn't exist
            self.currentProfile = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            self.profiles = try decoder.decode([UserProfile].self, from: data)
            print("Profiles loaded from \(fileURL.path)")
            // Attempt to load a previously selected currentProfile, or default to first.
            // For simplicity now, just set to first if available.
            // A more robust way would be to save the ID of the currentProfile.
            if !self.profiles.isEmpty {
                self.currentProfile = self.profiles.first
            } else {
                self.currentProfile = nil
            }
        } catch {
            print("Error loading profiles: \(error.localizedDescription). Initializing with empty list.")
            self.profiles = []
            self.currentProfile = nil
        }
    }

    // MARK: - CRUD Methods
    func addProfile(name: String, f0: Double) {
        let newProfile = UserProfile(name: name, f0: f0)
        profiles.append(newProfile)
        saveProfiles()
        // Optionally, set the new profile as current
        // currentProfile = newProfile
    }

    func updateProfile(_ profile: UserProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            if currentProfile?.id == profile.id {
                currentProfile = profile
            }
            saveProfiles()
        } else {
            print("Error: Profile with id \(profile.id) not found for update.")
        }
    }

    func deleteProfile(profile: UserProfile) {
        profiles.removeAll { $0.id == profile.id }
        if currentProfile?.id == profile.id {
            currentProfile = profiles.first // Select first or nil if empty
        }
        saveProfiles()
    }

    func deleteProfile(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        // Check if the current profile was deleted
        if let current = currentProfile, !profiles.contains(where: { $0.id == current.id }) {
            currentProfile = profiles.first
        }
        saveProfiles()
    }

    func selectProfile(_ profile: UserProfile) {
        if profiles.contains(where: { $0.id == profile.id }) {
            currentProfile = profile
            // Optionally save the ID of the current profile to UserDefaults here
            // so it can be restored on next app launch.
            print("Profile \(profile.name) selected.")
        } else {
            print("Error: Attempted to select a profile not in the list.")
        }
    }

    func selectProfile(byId id: UUID?) {
        guard let profileId = id else {
            currentProfile = nil
            return
        }
        currentProfile = profiles.first(where: { $0.id == profileId })
    }
}
