import SwiftUI

struct TunerViewTemplate: View {
    // Main App State
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    
    // Recording State
    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @State private var countdown: Int? = nil
    let countdownSeconds = 3
    @State private var recordingStartedAt: Date?
    
    // User Profile Info (replace with your own source if needed)
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78

    // Add this state to control sheet presentation
    @State private var showingProfileSelector = false
    
    var body: some View {
        VStack(spacing: 28) {
            // ------- Profile Selection Bar -------
            HStack {
                Button(action: { showingProfileSelector = true }) {
                    Label(profileManager.currentProfile?.name ?? "Select Profile", systemImage: "person.crop.circle")
                        .font(.headline)
                        .padding(7)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                Spacer()
                // You could add a transposition or modifier toggle here too!
            }
            .padding(.top)
            .padding(.horizontal)

            // ------- Visual Section -------
            VStack(spacing: 8) {
                Text("User f₀: \(userF0, specifier: "%.2f") Hz")
                    .font(.headline)
                Text("Live Pitch: \(tunerData.pitch.measurement.value, specifier: "%.2f") Hz")
                    .font(.title2)
            }
            .padding(.top)

            // ------- Recording Controls -------
            HStack(spacing: 18) {
                Button(action: {
                    if tunerData.isRecording {
                        tunerData.stopRecording()
                        let sessionDuration = Date().timeIntervalSince(recordingStartedAt ?? Date())
                        sessionStats = tunerData.calculateStatisticsExtended(duration: max(0, sessionDuration))
                        showStatsModal = true
                        recordingStartedAt = nil
                    } else {
                        countdown = countdownSeconds
                        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                            if let c = countdown, c > 1 {
                                countdown = c - 1
                            } else {
                                timer.invalidate()
                                countdown = nil
                                tunerData.startRecording()
                                sessionStats = nil
                                recordingStartedAt = Date()
                            }
                        }
                    }
                }) {
                    Text(tunerData.isRecording ? "Stop Recording" : "Start Recording")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(tunerData.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    tunerData.clearRecording()
                    sessionStats = nil
                    recordingStartedAt = nil
                }) {
                    Text("Clear Data")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showStatsModal) {
                if let stats = sessionStats {
                    StatsModalView(
                        statistics: stats.pitch,
                        duration: stats.duration,
                        values: tunerData.recordedPitches,
                        profileName: profileManager.currentProfile?.name ?? "Guest"
                    )
                }
            }

            Spacer()
        }
        .sheet(isPresented: $showingProfileSelector) {
            ProfileSelectionView(profileManager: profileManager, isPresented: $showingProfileSelector)
        }
        .onAppear {
            // Optionally sync userF0 with the current profile
            if let currentF0 = profileManager.currentProfile?.f0 {
                userF0 = currentF0
            } else if let defaultF0 = profileManager.profiles.first?.f0 {
                userF0 = defaultF0
            }
        }
        .onChange(of: profileManager.currentProfile) { newProfile in
            if let newF0 = newProfile?.f0, userF0 != newF0 {
                userF0 = newF0
            }
        }
        .padding()
    }
}


// Example preview (requires sample TunerData/UserProfileManager in your project)
struct TunerViewTemplate_Previews: PreviewProvider {
    static var previews: some View {
        TunerViewTemplate(
            tunerData: .constant(TunerData(pitch: 220, amplitude: 0.4)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .environmentObject(UserProfileManager())
        .previewLayout(.sizeThatFits)
    }
}
