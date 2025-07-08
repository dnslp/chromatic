import SwiftUI
import AVFoundation     // NEW

// MARK: - TunerView
struct TunerView: View {
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    
    @StateObject private var profileManager = UserProfileManager()
    @State private var userF0: Double = 77.78 // Default, will be updated from profileManager
    @State private var micMuted = false
    @State private var sessionStats: SessionStatistics?   // Updated!
    @State private var showStatsModal = false
    @State private var showingProfileSelector = false // For presenting ProfileSelectionView
    
    @State private var countdown: Int? = nil    // nil = not counting down
    let countdownSeconds = 7
    
    
    // Timer State
    @State private var recordingStartedAt: Date?
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var elapsed: TimeInterval {
        guard let start = recordingStartedAt else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }
    
    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false
    
    // Layout constants
    private let watchHeight: CGFloat = 150
    private let nonWatchHeight: CGFloat = 560
    private let menuHeight: CGFloat = 44
    private let contentSpacing: CGFloat = 8
    private let noteTicksHeight: CGFloat = 100
    private let amplitudeBarHeight: CGFloat = 32
    private let maxCentDistance: Double = 50
    
    // Helper to format time as MM:SS or H:MM:SS
    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    struct CalmingCountdownCircle: View {
        let secondsLeft: Int
        let totalSeconds: Int
        
        var percent: Double {
            1.0 - Double(secondsLeft-1) / Double(totalSeconds)
        }
        
        @State private var animatePulse = false
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [
                            Color.blue.opacity(0.18),
                            Color.purple.opacity(0.12)
                        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(animatePulse ? 1.04 : 1)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animatePulse)
                    .onAppear { animatePulse = true }
                Circle()
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [
                            Color.blue.opacity(0.2),
                            Color.blue.opacity(0.5),
                            Color.purple.opacity(0.6),
                            Color.blue.opacity(0.2)
                        ]), center: .center),
                        lineWidth: 8
                    )
                Circle()
                    .trim(from: 0, to: percent)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: percent)
            }
        }
    }
    
    
    var body: some View {
        Group {
#if os(watchOS)
            // watchOS unchanged...
            ZStack { /* ... */ }
#else
            HStack(spacing: 1) {
                // ────────── VERTICAL VISUALIZER ──────────
                PitchLineVisualizer(
                    tunerData: tunerData,
                    frequency: tunerData.pitch,
//                    fundamental: Frequency(floatLiteral: userF0),
                    profile: profileManager.currentProfile // Pass the whole profile
                )
                .frame(width: 10)
                .padding(.vertical, 1)
                
                // ────────── MAIN CONTENT ──────────
                VStack(spacing: 0) {
                    // ───── AMPLITUDE BAR ─────
                    HStack(spacing: 8) {
                        Text("Level")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .frame(height: 6)
                                    .foregroundColor(Color.secondary.opacity(0.14))
                                Capsule()
                                    .frame(
                                        width: geo.size.width *
                                        CGFloat(micMuted ? 0 : tunerData.amplitude),
                                        height: 6)
                                    .foregroundColor(
                                        Color(hue: 0.1 - 0.1 * tunerData.amplitude,
                                              saturation: 0.9,
                                              brightness: 0.9)
                                    )
                                    .animation(.easeInOut, value: tunerData.amplitude)
                            }
                        }
                        .frame(height: amplitudeBarHeight)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: amplitudeBarHeight)
                    .background(Color(.systemBackground).opacity(0.85))
                    .cornerRadius(8)
                    .shadow(radius: 2, y: -1)
                    
                    // ───── NOTE DISPLAY ─────
                    VStack(spacing: contentSpacing) {
                        MatchedNoteView(match: match, modifierPreference: modifierPreference)
                            .padding(.top, 50)
                        MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                            .padding(.bottom, 50)
                        NoteTicks(tunerData: tunerData, showFrequencyText: true)
                            .frame(height: noteTicksHeight)
                            .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.top, 100)
                    
                    Spacer(minLength: 40)
                    
                    // ───── OTHER VISUALIZERS ─────
                    ConcentricCircleVisualizer(
                        distance: Double(match.distance.cents),
                        maxDistance: maxCentDistance,
                        tunerData: tunerData,
                        fundamentalHz: userF0
                    )
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 2)
                    
                    HarmonicGraphView(tunerData: tunerData)
                        .frame(height: 30)
                    PitchChakraTimelineView(pitches: tunerData.recordedPitches)
                        .frame(height: 48)
                    
                    // MARK: RECORD / STATS WITH TIMER
                    if let c = countdown {
                        VStack {
                            CalmingCountdownCircle(secondsLeft: c, totalSeconds: countdownSeconds)
                                .frame(width: 140, height: 140)
                                .padding(.bottom, 8)
                            Text("Recording begins in \(c)…")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 16) {
                            Button(action: {
                                if tunerData.isRecording {
                                    tunerData.stopRecording()
                                    let sessionDuration = Date().timeIntervalSince(recordingStartedAt ?? Date())
                                    sessionStats = tunerData.calculateStatisticsExtended(duration: max(0, sessionDuration))
                                    showStatsModal = true
                                    recordingStartedAt = nil
                                } else {
                                    // BEGIN COUNTDOWN
                                    countdown = countdownSeconds
                                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                                        if let c = countdown, c > 1 {
                                            countdown = c - 1
                                        } else {
                                            timer.invalidate()
                                            countdown = nil
                                            // Now actually start recording
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
                                    profileName: profileManager.currentProfile?.name ?? "Guest" // Pass profile name
                                )
                            }
                        }
                    }
                    
                    // ────────── PROFILE & TRANSPOSE CONTROLS ──────────
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
                    .padding(.horizontal, 8) // Add some padding to the HStack
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: nonWatchHeight)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.94))
                    .shadow(color: Color.black.opacity(0.05), radius: 16, y: 4)
            )
            .padding(.horizontal, 8)
#endif
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            if let currentF0 = profileManager.currentProfile?.f0 {
                userF0 = currentF0
            } else if let defaultF0 = profileManager.profiles.first?.f0 { // Fallback to first profile if current is nil
                userF0 = defaultF0
                profileManager.currentProfile = profileManager.profiles.first
            }
            // If profiles is empty, UserProfileManager init creates a default one and sets it to current.
            // So currentProfile should ideally not be nil here if manager is initialized.
        }
        .onChange(of: profileManager.currentProfile) { newProfile in
            if let newF0 = newProfile?.f0 {
                if userF0 != newF0 { // Update only if different to avoid potential loops
                    userF0 = newF0
                }
            }
        }
        .onChange(of: userF0) { newValue in
            if var current = profileManager.currentProfile, current.f0 != newValue {
                current.f0 = newValue
                profileManager.updateProfile(current)
            }
            // Consider what happens if currentProfile is nil.
            // Should changing userF0 prompt to create a new profile?
            // For now, it only updates if a profile is selected.
        }
        .sheet(isPresented: $showingProfileSelector) {
            ProfileSelectionView(profileManager: profileManager, isPresented: $showingProfileSelector)
        }
    }
}

// MARK: - TunerView Preview
struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView(
            tunerData: .constant(TunerData(pitch: 428, amplitude: 0.5)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
