//
//  TunerViewZen.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//


//
//  TunerViewZen.swift
//  Chromatic
//
//  Created by David Nyman on 2025-07-09.
//

import SwiftUI
import AVFoundation

struct TunerViewZen: View {
    @Binding var tunerData: TunerData
    @State var userF0: Double = 77.78
    @State private var countdown: Int? = nil
    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @EnvironmentObject private var profileManager: UserProfileManager

    // Layout
    private let circleSize: CGFloat = 290
    let countdownSeconds = 3
    @State private var recordingStartedAt: Date?

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[0])
    }
    private let maxCentDistance: Double = 50

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

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            ZStack {
                let centsOffset = tunerData.pitch.measurement.value > 0 && userF0 > 0
                    ? 1200 * log2(tunerData.pitch.measurement.value / userF0)
                    : 0

                ConcentricCircleVisualizer(
                    distance: centsOffset,
                    maxDistance: 50,
                    tunerData: tunerData,
                    fundamentalHz: userF0
                )
                .frame(width: 220, height: 220)

                if let c = countdown {
                    CalmingCountdownCircle(secondsLeft: c, totalSeconds: countdownSeconds)
                        .frame(width: circleSize, height: circleSize)
                }
            }

            if let c = countdown {
                Text("Recording begins in \(c)…")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 20) {
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
                        .padding(.vertical, 10)
                        .background(tunerData.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                }
                .disabled(countdown != nil)

                Button(action: {
                    tunerData.clearRecording()
                    sessionStats = nil
                    recordingStartedAt = nil
                }) {
                    Text("Clear Data")
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                }
                .disabled(tunerData.isRecording || countdown != nil)
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
        .onAppear {
            // Pick up profile's f0 on load
            if let currentF0 = profileManager.currentProfile?.f0 {
                userF0 = currentF0
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
        .padding()
    }
}

// MARK: - Preview

struct TunerViewZen_Previews: PreviewProvider {
    static var previews: some View {
        TunerViewZen(
            tunerData: .constant(TunerData(pitch: 77.00, amplitude: 0.5))
        )
        .environmentObject(UserProfileManager())
        .previewLayout(.device)
        .padding()
    }
}
