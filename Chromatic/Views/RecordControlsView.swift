import SwiftUI

struct RecordControlsView: View {
    @Binding var tunerData: TunerData
    @EnvironmentObject private var profileManager: UserProfileManager

    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @State private var countdown: Int? = nil
    private let countdownSeconds = 3
    @State private var recordingStartedAt: Date?

    struct CalmingCountdownCircle: View {
        let secondsLeft: Int
        let totalSeconds: Int
        var percent: Double { 1.0 - Double(secondsLeft - 1) / Double(totalSeconds) }
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
                Button(action: toggleRecording) {
                    Text(tunerData.isRecording ? "Stop Recording" : "Start Recording")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(tunerData.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: clearData) {
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
        }
    }

    private func toggleRecording() {
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
    }

    private func clearData() {
        tunerData.clearRecording()
        sessionStats = nil
        recordingStartedAt = nil
    }
}
