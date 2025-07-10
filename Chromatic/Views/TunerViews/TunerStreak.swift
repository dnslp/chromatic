//
//  TunerStreak.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//

import SwiftUI

// MARK: - Helper Structs (assuming spectrumColors, CircleWave, WavingCircleBorder, AtomicCountdownView are globally available)

// If WavingCircleBorder, CircleWave etc. are confirmed to be in StringTheoryView.swift or another global spot,
// these comments should ideally be added to those original definitions.
// For now, adding them here if we were to temporarily redefine/use it locally during refactoring.
// NOTE: If these structs are indeed global, this edit block should be applied to their source files, not here.

/*
struct WavingCircleBorder: View {
    /// `strength`: Defines the amplitude of the wave. Higher values create more pronounced inward/outward movement.
    /// Example: 0.5 = subtle, 5 = very wavy.
    var strength: CGFloat = 1

    /// `frequency`: Number of wave crests around the circle's circumference.
    /// Example: 2 = two large waves, 20 = twenty small ripples.
    var frequency: CGFloat = 2

    /// `lineWidth`: The thickness of the circular line being drawn.
    var lineWidth: CGFloat = 3

    /// `color`: The base color of the waving line (when not highlighted).
    var color: Color = .green

    /// `animationDuration`: The time in seconds for one full wave cycle to complete (e.g., for a crest to travel all the way around).
    /// Shorter duration means faster animation.
    var animationDuration: Double = 2

    /// `highlighted`: When true, typically changes appearance (e.g., color to yellow, increased wave strength/lineWidth via internal logic).
    var highlighted: Bool = false

    /// `autoreverses`: If true, the animation will play forwards then backwards. StringTheoryView kept this false for continuous flow.
    var autoreverses: Bool = false

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Circle() // Static background portion of the circle
                .stroke(color.opacity(0.13), lineWidth: lineWidth)

            CircleWave( // The animated part
                // When highlighted, wave strength is amplified (e.g., by 2.2x)
                strength: highlighted ? strength * 2.2 : strength,
                frequency: frequency,
                phase: phase
            )
            // When highlighted, stroke color changes (e.g., to yellow) and line width doubles
            .stroke(highlighted ? .yellow : color, lineWidth: highlighted ? lineWidth * 2 : lineWidth)
            // Shadow effect, more pronounced when highlighted
            .shadow(color: highlighted ? .yellow : color.opacity(0.4), radius: highlighted ? 20 : 6)
            .animation(
                Animation.linear(duration: animationDuration)
                    .repeatForever(autoreverses: autoreverses), // Set to true to see back-and-forth
                value: phase
            )
        }
        .frame(width: highlighted ? 135 : 110, height: highlighted ? 135 : 110) // Default frame, can be overridden
        .onAppear { phase = .pi * 2 } // Start animation
    }
}
*/

// Data structure for solidified layers in the accretion model
struct StreakLayer: Identifiable {
    let id = UUID()
    let milestoneIndex: Int // e.g., 0 for first 10 pts, 1 for 11-20 pts
    var size: CGFloat        // Size at the time of solidification
    var color: Color
    // Add any other properties needed for layer-specific animation or appearance
    var animationStrength: CGFloat = 1.0
    var animationFrequency: CGFloat = 6.0
    var animationDuration: Double = 2.5
}


struct TunerStreak: View {
    // MARK: – Inputs
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int

    // MARK: – Recording State
    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @State private var countdown: Int?
    let countdownSeconds = 3
    @State private var recordingStartedAt: Date?

    // MARK: – Profile & F₀
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78

    // MARK: – Streak Tracking
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var updateCount: Int = 0 // Tracks pitch updates for streak points
    private let updatesPerPoint: Int = 5    // Number of in-tune updates to earn 1 streak point
    private let inTuneThreshold: Double = 5.0 // Cents tolerance for being in-tune

    // Accretion Model State
    @State private var solidifiedLayers: [StreakLayer] = []
    private var currentMilestoneIndex: Int { currentStreak / 10 }
    private var pointsInCurrentMilestone: Int { currentStreak % 10 }

    // Constants for Core Element visualization
    private let coreBaseSize: CGFloat = 35
    private let coreGrowthFactor: CGFloat = 5

    // MARK: – Profile Sheet
    @State private var showingProfileSelector = false

    var body: some View {
        VStack(spacing: 28) {
            // Profile selector
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
            .padding(.top)
            .padding(.horizontal)

            // Countdown
            if let c = countdown {
                AtomicCountdownView(countdown: c, total: countdownSeconds, color: .cyan)
                    .transition(.scale.combined(with: .opacity))
            }

            // Planetary Accretion Visualizer
            ZStack {
                // Part 1: Render Solidified Layers
                ForEach(solidifiedLayers) { layer in
                    WavingCircleBorder(
                        strength: layer.animationStrength,
                        frequency: layer.animationFrequency,
                        lineWidth: 2.0, // Solidified layers have a consistent, thinner line
                        color: layer.color,
                        animationDuration: layer.animationDuration,
                        highlighted: false // Solidified layers are never "yellow" highlighted
                    )
                    .frame(width: layer.size, height: layer.size)
                    .opacity(0.3 + (0.7 * (CGFloat(layer.milestoneIndex + 1) / CGFloat(solidifiedLayers.count + 1)))) // Older layers slightly fainter
                }

                // Part 2: Render the Active Growing Core Element
                // coreBaseSize and coreGrowthFactor are now struct-level constants
                let coreCurrentSize = coreBaseSize + CGFloat(pointsInCurrentMilestone) * coreGrowthFactor

                let coreColor = spectrumColors[currentMilestoneIndex % spectrumColors.count]
                let isCoreHighlighted = abs(tunerData.pitch.measurement.value - userF0) <= inTuneThreshold && tunerData.isRecording

                WavingCircleBorder(
                    strength: 1.5 + CGFloat(pointsInCurrentMilestone) * 0.1,
                    frequency: 10 + CGFloat(pointsInCurrentMilestone) * 0.5, // Slower frequency change
                    lineWidth: 2.5 + CGFloat(pointsInCurrentMilestone) * 0.15, // Slower lineWidth change
                    color: coreColor,
                    animationDuration: 1.6 - Double(pointsInCurrentMilestone) * 0.06, // Slower duration change
                    highlighted: isCoreHighlighted
                )
                .frame(width: coreCurrentSize, height: coreCurrentSize)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: coreCurrentSize) // Animate size change
                .animation(.easeInOut, value: isCoreHighlighted) // Animate highlight change


                // Guidance Chevrons (if not in tune and not highlighted)
                let diff = tunerData.pitch.measurement.value - userF0
                if !isCoreHighlighted && tunerData.isRecording { // Show chevrons only if recording and not in tune
                    if diff < -inTuneThreshold {
                        Image(systemName: "chevron.left.2")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            // Adjust offset based on core size or fixed position
                            .offset(x: -(coreCurrentSize/2 + 25))
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut, value: diff)
                    } else if diff > inTuneThreshold {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            .offset(x: coreCurrentSize/2 + 25)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut, value: diff)
                    }
                }
            }
            .frame(width: 280, height: 280) // Main ZStack frame
            .padding(.top)
            .opacity(countdown == nil ? 1 : 0.25)
            .onChange(of: tunerData.pitch.measurement.value) { newPitch in
                guard tunerData.isRecording, countdown == nil else { return }
                updateCount += 1
                if abs(newPitch - userF0) <= inTuneThreshold {
                    if updateCount % updatesPerPoint == 0 {
                        let oldMilestoneIndex = currentMilestoneIndex
                        let oldMilestoneIndex = self.currentMilestoneIndex
                        currentStreak += 1
                        bestStreak = max(bestStreak, currentStreak)

                        if self.currentMilestoneIndex > oldMilestoneIndex {
                            // Milestone completed, solidify a new layer
                            let layerSize = coreBaseSize + CGFloat(9) * coreGrowthFactor // Size at 9 points
                            let layerColor = spectrumColors[oldMilestoneIndex % spectrumColors.count]

                            // Apply golden ratio to animation params of solidified layers for variety
                            let phi = 1.618
                            let baseLayerAnimDuration = 2.5
                            let durationFactors = [1.0, 1.0/phi, phi]
                            let layerAnimDuration = baseLayerAnimDuration * durationFactors[oldMilestoneIndex % durationFactors.count]

                            let baseLayerFreq: CGFloat = 4.0
                            let freqFactors: [CGFloat] = [1.0, 1.0/phi, phi]
                            let layerFreq = baseLayerFreq * freqFactors[oldMilestoneIndex % freqFactors.count]

                            let newLayer = StreakLayer(
                                milestoneIndex: oldMilestoneIndex,
                                size: layerSize,
                                color: layerColor,
                                animationStrength: 1.0, // Less strength for solidified layers
                                animationFrequency: layerFreq,
                                animationDuration: layerAnimDuration
                            )
                            solidifiedLayers.append(newLayer)
                        }
                    }
                }
            }

            // Pitch and streak text below visualizer
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
            .padding(.top, 5) // Add some space above the text block

            // Recording controls
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
        .background(Color.black.ignoresSafeArea(.all)) // Dark background
    }

    // MARK: – Helpers

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
                    solidifiedLayers.removeAll() // Clear layers on new recording
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
        solidifiedLayers.removeAll() // Clear layers
    }

    private func syncF0WithProfile() {
        if let f0 = profileManager.currentProfile?.f0 {
            userF0 = f0
        }
    }
}

struct TunerStreak_Previews: PreviewProvider {
    static var previews: some View {
        let mockTunerData: TunerData = {
            var data = TunerData(pitch: 220, amplitude: 0.4)
            data.isRecording = true // Set isRecording for active state preview
            return data
        }()

        NavigationView { // Added for better preview context if needed
            TunerStreak(
                tunerData: .constant(mockTunerData),
                modifierPreference: .preferSharps,
                selectedTransposition: 0
            )
            .environmentObject(UserProfileManager.mock) // Using a mock for consistency
        }
        .preferredColorScheme(.dark) // Preview in dark mode
    }
}

// Mock UserProfileManager for preview
extension UserProfileManager {
    static var mock: UserProfileManager {
        let manager = UserProfileManager()
        manager.profiles = [
            UserProfile(name: "Tenor", f0: 146.83),
            UserProfile(name: "Soprano", f0: 329.63)
        ]
        manager.currentProfile = manager.profiles.first
        return manager
    }
}
