import SwiftUI

struct ProfileTabView: View {
    @StateObject private var profileManager = UserProfileManager()

    var body: some View {
        // The NavigationView from ProfileSelectionView will be used.
        // If ProfileSelectionView itself is not wrapped in NavigationView,
        // then this NavigationView here would be appropriate.
        // For now, let's assume ProfileSelectionView handles its own navigation title etc.
        ProfileSelectionView(profileManager: profileManager)
    }
}

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView()
            .environmentObject(UserProfileManager()) // Ensure preview has access if needed by children
    }
}
