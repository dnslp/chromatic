import SwiftUI

struct TunerViewTemplate: View {
    // Main App State
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    // --- INTERNAL STREAK STATE ---
    @State private var streak: Int = 0

    // Recording State
    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @State private var countdown: Int? = nil
    let countdownSeconds = 3
    @State private var recordingStartedAt: Date?

    // User Profile Info
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78

    // Sheet for profile selection
    @State private var showingProfileSelector = false
    
    // Used for streak logic
    @State private var lastMatched: Bool = false

    var body: some View {
        VStack(spacing: 10) {
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
            }
            .padding(.top)
            .padding(.horizontal)
        

            // --------- COUNTDOWN TIMER ----------
            if let c = countdown {
                Text("\(c)")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.vertical, 12)
                    .transition(.scale)
            }

            // ------- Visual Section -------
            VStack(spacing: 8) {
                Text("User f₀: \(userF0, specifier: "%.2f") Hz")
                    .font(.headline)
                Text("Live Pitch: \(tunerData.pitch.measurement.value, specifier: "%.2f") Hz")
                    .font(.title2)
            }
            .padding(.top)
            .opacity(countdown == nil ? 1 : 0.25) // Fade during countdown

            // ------- Streak Visualization -------
  
            MusicalPitchView(tunerData: $tunerData, modifierPreference: modifierPreference, selectedTransposition: 0)
            StreakBar(streak: streak)
            
            
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
                    Text(
                        tunerData.isRecording
                        ? "Stop Recording"
                        : (countdown != nil ? "\(countdown!)..." : "Start Recording")
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(tunerData.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(countdown != nil && !tunerData.isRecording)

                Button(action: {
                    tunerData.clearRecording()
                    sessionStats = nil
                    recordingStartedAt = nil
                    streak =  0
                }) {
                    Text("Clear Data")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(countdown != nil) // Lock out while countdown
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
        // ---- THE STREAK LOGIC ----
        .onChange(of: tunerData.pitch.measurement.value) { newPitch in
            // Only update if recording and not during countdown
            guard tunerData.isRecording && countdown == nil else { return }
            let percentTolerance = 0.02 // 2%
            let threshold = userF0 * percentTolerance
            let isMatching = abs(newPitch - userF0) < threshold
            if isMatching {
                streak += 1
            }
        }
        .padding()
    }
}

struct SpiralArcShape: Shape {
    var progress: CGFloat      // 0...1, how much of the current lap
    var laps: Int              // How many full turns have been completed
    var turnsPerCycle: Int     // How many turns to complete one lap (e.g., 1 = 360º/cycle)
    var spiralSpacing: CGFloat // Distance between spiral arms

    // This animatableData enables smooth transitions
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2 - spiralSpacing
        let totalLaps = CGFloat(laps) + progress
        let angleEnd = 2 * .pi * totalLaps * CGFloat(turnsPerCycle)

        var path = Path()
        let steps = max(200, Int(angleEnd * 40)) // Smoothness

        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let theta = angleEnd * t
            let radius = (theta / (2 * .pi * CGFloat(turnsPerCycle))) * spiralSpacing
            let clampedRadius = min(radius, maxRadius)
            let point = CGPoint(
                x: center.x + clampedRadius * cos(theta - .pi / 2),
                y: center.y + clampedRadius * sin(theta - .pi / 2)
            )
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

// --- StreakBar for animated visualization ---
struct StreakBar: View {
    var streak: Int
    var cycleLength: Int = 30      // How many streaks per spiral "lap"
    var spiralSpacing: CGFloat = 12
    var lineWidth: CGFloat = 1
    var turnsPerCycle: Int = 1     // 1 = full turn per cycle (can be >1 for denser spiral)
    var size: CGFloat = 100

    var progress: CGFloat {
        CGFloat(streak % cycleLength) / CGFloat(cycleLength)
    }
    var completedCycles: Int {
        streak / cycleLength
    }

    var body: some View {
        ZStack {
            // Draw the spiral
            SpiralArcShape(progress: progress, laps: completedCycles, turnsPerCycle: turnsPerCycle, spiralSpacing: spiralSpacing)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.orange, Color.yellow, Color.orange]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth + CGFloat(completedCycles), lineCap: .round)
                )
                .shadow(color: .orange.opacity(0.4), radius: 10)
                .animation(.smooth(duration: 0.5), value: streak)
                .frame(width: size, height: size)

            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(streak)")
                    .font(.title.bold())
            }
        }
        .frame(width: size, height: size)
        .padding()
    }
}

struct SpiralStreakBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StreakBar(streak: 5)
            StreakBar(streak: 29)
            StreakBar(streak: 31)
            StreakBar(streak: 700)
        }
        .padding()
    }
}



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
