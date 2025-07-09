import SwiftUI
import AVFoundation

struct TunerView: View {
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    var detailLevel: TunerDetailLevel = .all

    @State private var showingToneSettings = false
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78

    private let nonWatchHeight: CGFloat = 560

    var body: some View {
        HStack(spacing: 1) {
            PitchLineVisualizer(
                tunerData: tunerData,
                frequency: tunerData.pitch,
                profile: profileManager.currentProfile
            )
            .frame(width: 20)
            .padding(.vertical, 10)

            VStack(spacing: 0) {
                if detailLevel.contains(.pitchDisplay) {
                    PitchDisplayView(
                        tunerData: tunerData,
                        modifierPreference: modifierPreference,
                        selectedTransposition: selectedTransposition
                    )
                }

                if detailLevel.contains(.centeringRing) {
                    CenteringRingView(
                        tunerData: tunerData,
                        selectedTransposition: selectedTransposition,
                        userF0: userF0
                    )
                }

                if detailLevel.contains(.harmonicGraph) {
                    HarmonicGraphView(tunerData: tunerData)
                        .frame(height: 30)
                    PitchChakraTimelineView(pitches: tunerData.recordedPitches)
                        .frame(height: 48)
                }

                if detailLevel.contains(.recordControls) {
                    RecordControlsView(tunerData: $tunerData)
                }

                if detailLevel.contains(.profileMenu) {
                    ProfileMenuView(userF0: $userF0, selectedTransposition: $selectedTransposition)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: nonWatchHeight)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 16, y: 4)
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingToneSettings = true } label: {
                    Label("Tone Settings", systemImage: "slider.horizontal.3")
                }
            }
        }
        .onAppear {
            if let currentF0 = profileManager.currentProfile?.f0 {
                userF0 = currentF0
            } else if let defaultF0 = profileManager.profiles.first?.f0 {
                userF0 = defaultF0
                profileManager.currentProfile = profileManager.profiles.first
            }
        }
        .onChange(of: profileManager.currentProfile) { newProfile in
            if let newF0 = newProfile?.f0, userF0 != newF0 {
                userF0 = newF0
            }
        }
        .onChange(of: userF0) { newValue in
            if var current = profileManager.currentProfile, current.f0 != newValue {
                current.f0 = newValue
                profileManager.updateProfile(current)
            }
        }
    }
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: .constant(TunerData(pitch: 428, amplitude: 0.5)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .environmentObject(UserProfileManager())
        .previewLayout(.device)
        .padding()
    }
}
