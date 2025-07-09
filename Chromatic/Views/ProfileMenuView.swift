import SwiftUI

struct ProfileMenuView: View {
    @Binding var userF0: Double
    @Binding var selectedTransposition: Int
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var showingProfileSelector = false
    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false

    private let menuHeight: CGFloat = 44

    var body: some View {
        HStack {
            Button {
                showingProfileSelector = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text(profileManager.currentProfile?.name ?? "Profiles")
                        .font(.caption)
                        .lineLimit(1)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
            .padding(.trailing, 4)

            F0SelectorView(f0Hz: $userF0)

            if !hidesTranspositionMenu {
                TranspositionMenu(selectedTransposition: $selectedTransposition)
                    .padding(.leading, 8)
            }
            Spacer()
        }
        .frame(height: menuHeight)
        .padding(.horizontal, 8)
        .sheet(isPresented: $showingProfileSelector) {
            ProfileSelectionView(profileManager: profileManager, isPresented: $showingProfileSelector)
        }
    }
}
