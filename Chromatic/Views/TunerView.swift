import SwiftUI
import AVFoundation

// MARK: - TunerView

struct TunerView: View {
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    
    @State private var showingToneSettings = false
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78
    @State private var micMuted = false
    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @State private var showingProfileSelector = false
    @State private var countdown: Int? = nil
    let countdownSeconds = 3

    // Timer State
    @State private var recordingStartedAt: Date?
    private var elapsed: TimeInterval {
        guard let start = recordingStartedAt else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }
    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false
    
    // Layout constants
    private let nonWatchHeight: CGFloat = 560
    private let menuHeight: CGFloat = 44
    private let contentSpacing: CGFloat = 8
    private let noteTicksHeight: CGFloat = 100
    private let amplitudeBarHeight: CGFloat = 32
    private let maxCentDistance: Double = 50

    // MARK: - Helper Views
    struct CalmingCountdownCircle: View {
        let secondsLeft: Int
        let totalSeconds: Int
        var percent: Double { 1.0 - Double(secondsLeft-1) / Double(totalSeconds) }
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
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2)
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

    // MARK: - Main Body
    var body: some View {
        HStack(spacing: 0) {
            // ────────── VERTICAL VISUALIZER ──────────
            PitchLineVisualizer(
                tunerData: tunerData,
                frequency: tunerData.pitch,
                profile: profileManager.currentProfile
            )
            .frame(width: 34)
            .padding(.vertical, 10)
            
            // ────────── MAIN CONTENT ──────────
            VStack(spacing: 0) {
                // ───── NOTE DISPLAY ─────
                VStack(spacing: contentSpacing) {
                    MatchedNoteView(match: match, modifierPreference: modifierPreference)
                        .padding(.top, 5)
                    MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                        .padding(.bottom, 5)
                    NoteTicks(tunerData: tunerData, showFrequencyText: true)
                        .frame(height: noteTicksHeight)
                        .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.top, 0)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingToneSettings = true } label: {
                            Label("Tone Settings", systemImage: "slider.horizontal.3")
                        }
                    }
                }
                Spacer(minLength: 40)

                VStack(spacing: 12) {
                    // ───── Visualizer with Conditional Overlay ─────
                    ZStack {
                        ConcentricCircleVisualizer(
                            distance: Double(match.distance.cents),
                            maxDistance: maxCentDistance,
                            tunerData: tunerData,
                            fundamentalHz: userF0
                        )
                        .frame(width: 80, height: 80)
                        .padding(.bottom, 20)

                        if let c = countdown {
                            CalmingCountdownCircle(secondsLeft: c, totalSeconds: countdownSeconds)
                                .frame(width: 140, height: 140)
                        }
                    }
                    // Countdown text, only during countdown
                    if let c = countdown {
                        Text("Recording begins in \(c)…")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    // ───── Always Show These Buttons ─────
                    HStack(spacing: 16) {
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
                    // PitchChakraTimelineView
                    PitchChakraTimelineView(pitches: tunerData.recordedPitches)
                        .frame(height: 48)
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
                .padding(.horizontal, 0)
            }
            .frame(maxWidth: .infinity)
            
            // ────────── HARMONIC GRAPH ON RIGHT ──────────
            HarmonicGraphView(tunerData: tunerData)
                .frame(width: 4, height: 320) // <--- adjust width & height as needed
                .padding(.vertical, 8)
        }
        .frame(height: nonWatchHeight)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 16, y: 4)
        )
        .padding(.horizontal, 0)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingToneSettings = true
                } label: {
                    Label("Tone Settings", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showingProfileSelector) {
            ProfileSelectionView(profileManager: profileManager, isPresented: $showingProfileSelector)
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

// MARK: - TunerView Preview

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
