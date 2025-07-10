//
//  TunerStreak.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//

import SwiftUI

/// Renders concentric rings for each 10-point milestone
struct RingOverlay: View {
    let ringCount: Int

    var body: some View {
        ForEach(1...ringCount, id: \.self) { i in
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .frame(width: 100 + CGFloat(i) * 20,
                       height: 100 + CGFloat(i) * 20)
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
                Text("\(c)")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.vertical, 12)
                    .transition(.scale)
            }

            // Concentric rings & tuning indicator
            ZStack {
                if ringCount > 0 {
                    RingOverlay(ringCount: ringCount)
                }
                let diff = tunerData.pitch.measurement.value - userF0
                if abs(diff) <= inTuneThreshold {
                    Circle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 12, height: 12)
                } else if diff < -inTuneThreshold {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .offset(x: -80)
                } else {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .offset(x: 80)
                }
            }
            // Fixed frame to keep rings separate from text
            .frame(width: 240, height: 240)
            .padding(.top)
            .opacity(countdown == nil ? 1 : 0.25)
            .onChange(of: tunerData.pitch.measurement.value) { newPitch in
                guard tunerData.isRecording else { return }
                updateCount += 1
                if abs(newPitch - userF0) <= inTuneThreshold &&
                   updateCount % updatesPerPoint == 0 {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                }
            }

            // Pitch and streak text below rings
            VStack(spacing: 8) {
                Text("Target f₀: \(String(format: "%.2f", userF0)) Hz")
                    .font(.headline)
                Text("Live Pitch: \(String(format: "%.2f", tunerData.pitch.measurement.value)) Hz")
                    .font(.title2)
                Text("🔥 Streak: \(currentStreak) 🔥")
                    .font(.subheadline)
                    .foregroundColor(currentStreak > 0 ? .green : .primary)
            }

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
        TunerStreak(
            tunerData: .constant(TunerData(pitch: 220, amplitude: 0.4)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .environmentObject(UserProfileManager())
        .previewLayout(.sizeThatFits)
    }
}
