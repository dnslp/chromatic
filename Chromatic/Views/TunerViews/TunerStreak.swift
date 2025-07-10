//
//  TunerStreak.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//

import SwiftUI

/// Represents one concentric ring corresponding to a single streak point.
struct StreakLayer: Identifiable {
    let id = UUID()
    let milestoneIndex: Int    // Zero-based index: 0 for the first point, 1 for the second, etc.
    let size: CGFloat          // Diameter of this ring
    let color: Color           // Base color for the ring
    let animationStrength: CGFloat   // Amplitude of the waviness
    let animationFrequency: CGFloat  // Frequency of the waviness
    let animationDuration: Double    // Duration of one wave cycle
}

/// A view that visualizes the user’s tuning streak as a series of hypnotic concentric rings.
struct TunerStreak: View {
    // MARK: – Inputs

    // Contains live pitch measurements and recording controls
    @Binding var tunerData: TunerData
    // User’s preference for sharp/flat note modifiers (unused here but passed through)
    @State var modifierPreference: ModifierPreference
    // Transposition selector (passed through)
    @State var selectedTransposition: Int

    // MARK: – Recording State

    @State private var sessionStats: SessionStatistics?   // Stores stats to show in modal
    @State private var showStatsModal = false            // Controls stats modal presentation
    @State private var countdown: Int?                   // Optional 3-2-1 countdown
    let countdownSeconds = 3                             // Total countdown seconds
    @State private var recordingStartedAt: Date?         // Timestamp when recording begins

    // MARK: – Profile & Target Pitch (F₀)

    @EnvironmentObject private var profileManager: UserProfileManager  // Provides saved profiles
    @State private var userF0: Double = 77.78           // Target fundamental frequency

    // MARK: – Streak Tracking

    @State private var currentStreak: Int = 0    // Number of points earned
    @State private var bestStreak: Int = 0       // Maximum streak achieved
    @State private var updateCount: Int = 0      // Counts in-tune updates toward next point
    private let updatesPerPoint: Int = 5         // Number of in-tune samples per streak point
    private let inTuneThreshold: Double = 5.0    // Cents tolerance for being “in tune”

    // MARK: – Accretion Model State

    @State private var solidifiedLayers: [StreakLayer] = []  // Rings that have “solidified”
    private var pointsInCurrentStreak: Int { currentStreak } // Alias for clarity

    // MARK: – Visualization Constants

    private let coreBaseSize: CGFloat = 35       // Base diameter of the inner core
    private let coreGrowthFactor: CGFloat = 5    // Increment per streak point

    // MARK: – Hypnotic Animation State

    @State private var rotationAngle: Double = 0 // Controls continuous rotation of rings
    @State private var pulse = false            // Toggles core pulsing scale

    // MARK: – Profile Selector Sheet

    @State private var showingProfileSelector = false  // Controls profile-selection sheet

    var body: some View {
        VStack(spacing: 28) {
            // Profile selection bar at top
            HStack {
                Button(action: { showingProfileSelector = true }) {
                    Label(
                        profileManager.currentProfile?.name ?? "Select Profile",
                        systemImage: "person.crop.circle"
                    )
                    .font(.headline)
                    .padding(7)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            // 3-2-1 Countdown Display
            if let c = countdown {
                AtomicCountdownView(countdown: c, total: countdownSeconds, color: .cyan)
                    .transition(.scale.combined(with: .opacity))
            }

            // MARK: – Hypnotic Accretion Visualizer
            ZStack {
                // 1) Rotating halo with an angular gradient
                WavingCircleBorder(
                    strength: 1, frequency: 7, lineWidth: 4, color: .green, animationDuration: 1, autoreverses: false
                )
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.green, .blue, .green]),
                            center: .center
                        ),
                        lineWidth: 20   // Fixed thin halo
                    )
                    .frame(width: 230, height: 230 )
                    .rotationEffect(.degrees(rotationAngle))

                // 2) Solidified rings for each past streak point
                ForEach(solidifiedLayers) { layer in
                    WavingCircleBorder(
                        strength: layer.animationStrength,
                        frequency: layer.animationFrequency,
                        lineWidth: 2,  // Uniform stroke thickness for past layers
                        color: layer.color,
                        animationDuration: layer.animationDuration,
                        highlighted: false
                    )
                    .frame(width: layer.size, height: layer.size)
                    .opacity(0.3 + 0.7 * (CGFloat(layer.milestoneIndex + 1) / CGFloat(solidifiedLayers.count + 1)))
                    .rotationEffect(.degrees(rotationAngle / Double(layer.milestoneIndex + 1)))
                }

                // 3) Pulsing active core that grows with current streak
                let coreSize = coreBaseSize + CGFloat(pointsInCurrentStreak) * coreGrowthFactor
                let coreColor = spectrumColors[pointsInCurrentStreak % spectrumColors.count]
                let isInTune = abs(tunerData.pitch.measurement.value - userF0) <= inTuneThreshold && tunerData.isRecording

                WavingCircleBorder(
                    strength: 1.5 + CGFloat(pointsInCurrentStreak) * 0.1,
                    frequency: 10 + CGFloat(pointsInCurrentStreak) * 0.005,
                    lineWidth: 2.5 + CGFloat(pointsInCurrentStreak) * 0.005, // Adjust if too large
                    color: coreColor,
                    animationDuration: max(0.5, 1.6 - Double(pointsInCurrentStreak) * 0.6),
                    highlighted: isInTune
        
                )
                .frame(width: coreSize, height: coreSize)
                .scaleEffect(pulse ? 1.1 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: coreSize)
                .animation(.easeInOut, value: isInTune)

                // 4) Directional chevrons guiding user if off-pitch
                if !isInTune && tunerData.isRecording {
                    let diff = tunerData.pitch.measurement.value - userF0
                    let chevron = diff < -inTuneThreshold ? "chevron.left.2" : "chevron.right.2"
                    Image(systemName: chevron)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.red.opacity(0.8))
                        .offset(x: diff < 0 ? -(coreSize/2 + 25) : (coreSize/2 + 25))
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut, value: diff)
                }
            }
            .frame(width: 280, height: 280)
            .padding(.top)
            .opacity(countdown == nil ? 1 : 0.25)
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }
            .onChange(of: tunerData.pitch.measurement.value) { newPitch in
                guard tunerData.isRecording, countdown == nil else { return }
                updateCount += 1
                if abs(newPitch - userF0) <= inTuneThreshold,
                   updateCount % updatesPerPoint == 0 {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)

                    // Compute new ring and append
                    let streakIndex = currentStreak - 1
                    let layerSize = coreBaseSize + CGFloat(streakIndex) * coreGrowthFactor
                    let layerColor = spectrumColors[streakIndex % spectrumColors.count]
                    let phi = 1.618
                    let baseDur = 2.5
                    let durFactors: [Double] = [1, 1/phi, phi]
                    let layerAnimDuration = baseDur * durFactors[streakIndex % durFactors.count]
                    let baseFreq: CGFloat = 4
                    let freqFactors: [CGFloat] = [1, 1/CGFloat(phi), CGFloat(phi)]
                    let layerFreq = baseFreq * freqFactors[streakIndex % freqFactors.count]
                    solidifiedLayers.append(
                        StreakLayer(
                            milestoneIndex: streakIndex,
                            size: layerSize,
                            color: layerColor,
                            animationStrength: 1.0,
                            animationFrequency: layerFreq,
                            animationDuration: layerAnimDuration
                        )
                    )
                }
            }

            // MARK: – Pitch & Streak Text
            VStack(spacing: 10) {
                Text("Target f₀: \(String(format: "%.2f", userF0)) Hz")
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                Text("Live Pitch: \(String(format: "%.2f", tunerData.pitch.measurement.value)) Hz")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.7), radius: 3)
                Text("🔥 Streak: \(currentStreak) 🔥")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(currentStreak > 0 ? .yellow : .gray)
                    .shadow(color: currentStreak > 0 ? .orange.opacity(0.8) : .clear, radius: 5)
                    .animation(.spring(), value: currentStreak)
                if bestStreak > 0 {
                    Text("Best: \(bestStreak)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.top, 5)

            // MARK: – Recording Controls
            HStack(spacing: 18) {
                Button(action: toggleRecording) {
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

                Button(action: clearSession) {
                    Text("Clear Data")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(countdown != nil)
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
            ProfileSelectionView(
                profileManager: profileManager,
                isPresented: $showingProfileSelector
            )
        }
        .onAppear(perform: syncF0WithProfile)
        .onChange(of: profileManager.currentProfile) { _ in syncF0WithProfile() }
        .padding()
        .background(Color.black.ignoresSafeArea(.all))
    }

    // MARK: – Helper Methods

    private func toggleRecording() {
        if tunerData.isRecording {
            tunerData.stopRecording()
            let duration = Date().timeIntervalSince(recordingStartedAt ?? Date())
            sessionStats = tunerData.calculateStatisticsExtended(duration: max(0, duration))
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
                    currentStreak = 0
                    bestStreak = 0
                    updateCount = 0
                    solidifiedLayers.removeAll()
                }
            }
        }
    }

    private func clearSession() {
        tunerData.clearRecording()
        sessionStats = nil
        recordingStartedAt = nil
        currentStreak = 0
        bestStreak = 0
        updateCount = 0
        solidifiedLayers.removeAll()
    }

    private func syncF0WithProfile() {
        if let f0 = profileManager.currentProfile?.f0 {
            userF0 = f0
        }
    }
}

// MARK: – Preview Helpers and Multiple States

extension TunerStreak {
    /// Initializes a preview instance with a preset streak count.
    init(previewStreak: Int) {
        let mock = TunerData(pitch: 220, amplitude: 0.4)
        _tunerData = .constant(mock)
        _modifierPreference = State(initialValue: .preferSharps)
        _selectedTransposition = State(initialValue: 0)
        // Build layers matching previewStreak
        let layers = (0..<previewStreak).map { idx in
            StreakLayer(
                milestoneIndex: idx,
                size: 35 + CGFloat(idx) * 5,
                color: spectrumColors[idx % spectrumColors.count],
                animationStrength: 1.0,
                animationFrequency: 4.0,
                animationDuration: 2.5
            )
        }
        _currentStreak = State(initialValue: previewStreak)
        _bestStreak = State(initialValue: previewStreak)
        _solidifiedLayers = State(initialValue: layers)
        _rotationAngle = State(initialValue: 0)
        _pulse = State(initialValue: false)
    }
}

struct TunerStreak_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TunerStreak(previewStreak: 10)
                .previewDisplayName("Streak: 10")
            TunerStreak(previewStreak: 20)
                .previewDisplayName("Streak: 20")
            TunerStreak(previewStreak: 30)
                .previewDisplayName("Streak: 30")
            TunerStreak(previewStreak: 40)
                .previewDisplayName("Streak: 40")
        }
        .environmentObject(UserProfileManager.mock)
        .preferredColorScheme(.dark)
    }
}

// Mock for Preview
extension UserProfileManager {
    static var mock: UserProfileManager {
        let m = UserProfileManager()
        m.profiles = [
            UserProfile(name: "Tenor", f0: 146.83),
            UserProfile(name: "Soprano", f0: 329.63)
        ]
        m.currentProfile = m.profiles.first
        return m
    }
}
