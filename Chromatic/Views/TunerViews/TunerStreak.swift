//
//  TunerStreak.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//

import SwiftUI

// MARK: - Helper Structs (assuming spectrumColors, CircleWave, WavingCircleBorder, AtomicCountdownView are globally available)

/// Renders concentric rings for each 10-point milestone
struct RingOverlay: View {
    let ringCount: Int
    let currentStreak: Int // Pass currentStreak to highlight the "active" ring

    var body: some View {
        ForEach(1...ringCount, id: \.self) { i in
            let isActive = i == ringCount // Highlight the outermost ring
            let colorIndex = (i - 1) % spectrumColors.count
            WavingCircleBorder(
                strength: 2,
                frequency: CGFloat(10 + i * 2), // Vary frequency for visual interest
                lineWidth: isActive ? 4 : 2.5,
                color: spectrumColors[colorIndex],
                animationDuration: 1.5 + Double(i) * 0.2,
                highlighted: isActive && currentStreak % 10 != 0 && currentStreak > 0 // Highlight if it's the current target ring
            )
            .frame(width: 100 + CGFloat(i) * 30, // Increased spacing for WavingCircleBorder
                   height: 100 + CGFloat(i) * 30)
        }
    }
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
    @State private var updateCount: Int = 0
    private let updatesPerPoint: Int = 5
    private let inTuneThreshold: Double = 5.0
    private var ringCount: Int { currentStreak / 10 }

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

            // Concentric rings & tuning indicator
            ZStack {
                // Rings based on streak milestones
                if ringCount > 0 {
                    RingOverlay(ringCount: ringCount, currentStreak: currentStreak)
                }

                // Central In-Tune/Guidance Indicator
                let isTuned = abs(tunerData.pitch.measurement.value - userF0) <= inTuneThreshold
                let diff = tunerData.pitch.measurement.value - userF0

                WavingCircleBorder(
                    strength: 1.5,
                    frequency: 12,
                    lineWidth: 3,
                    color: isTuned ? .green : .gray.opacity(0.7),
                    animationDuration: isTuned ? 1.0 : 2.5,
                    highlighted: isTuned
                )
                .frame(width: isTuned ? 90 : 80, height: isTuned ? 90 : 80) // Smaller central element
                .animation(.spring(), value: isTuned)

                // Guidance Chevrons (if not in tune)
                if !isTuned {
                    if diff < -inTuneThreshold {
                        Image(systemName: "chevron.left.2") // Using double chevron for more emphasis
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            .offset(x: -65) // Adjusted offset for central element
                            .transition(.opacity.combined(with: .scale))
                    } else if diff > inTuneThreshold {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            .offset(x: 65) // Adjusted offset for central element
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .frame(width: 280, height: 280) // Slightly larger frame to accommodate larger rings
            .padding(.top)
            .opacity(countdown == nil ? 1 : 0.25)
            .onChange(of: tunerData.pitch.measurement.value) { newPitch in
                guard tunerData.isRecording, countdown == nil else { return } // Ensure countdown is not active
                updateCount += 1
                if abs(newPitch - userF0) <= inTuneThreshold {
                    if updateCount % updatesPerPoint == 0 {
                        currentStreak += 1
                        bestStreak = max(bestStreak, currentStreak)
                    }
                } else {
                    // Optional: Reset streak if out of tune for a certain period, or just pause.
                    // For now, streak only increments when in tune.
                }
            }

            // Pitch and streak text below rings
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
