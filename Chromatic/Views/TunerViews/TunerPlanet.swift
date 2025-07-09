//
//  TunerPlanet.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//

import SwiftUI

struct TunerPlanet: View {
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

    // Profile Picker Sheet
    @State private var showingProfileSelector = false

    // Animate planetary intervals
    @State private var intervalParticleLevels: [Double] = []

    var intervals: [(name: String, ratio: Double, color: Color)] {
        let phi = 1.61803398875
        return [
            ("f₀", 1.0, .yellow),
            ("M2", 9/8, .green),
            ("M3", 5/4, .red),
            ("P4", 4/3, .cyan),
            ("P5", 3/2, .orange),
            ("M6", 5/3, .purple),
            ("M7", 15/8, .blue),
            ("8ve", 2.0, .mint),
            ("φ", phi, .pink)
        ]
    }

    let maxRadius: CGFloat = 120
    let ringThickness: CGFloat = 3
    let asteroidMax: Int = 36
    let tuningCents: Double = 25

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

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

            // ------- Planetary Intervals Visualization -------
            GeometryReader { geo in
                PlanetaryIntervalView(
                    f0: userF0,
                    liveHz: tunerData.pitch.measurement.value,
                    intervals: intervals,
                    particleLevels: $intervalParticleLevels,
                    maxRadius: maxRadius,
                    ringThickness: ringThickness,
                    asteroidMax: asteroidMax,
                    tuningCents: tuningCents
                )
                .frame(width: geo.size.width, height: geo.size.width)
            }
            .frame(height: maxRadius * 2.2)

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
            intervalParticleLevels = Array(repeating: 0.1, count: intervals.count)
        }
        .onChange(of: profileManager.currentProfile) { newProfile in
            if let newF0 = newProfile?.f0, userF0 != newF0 {
                userF0 = newF0
                intervalParticleLevels = Array(repeating: 0.1, count: intervals.count)
            }
        }
        .onChange(of: userF0) { _ in
            intervalParticleLevels = Array(repeating: 0.1, count: intervals.count)
        }
        .onReceive(timer) { _ in
            // Animate accumulation based on live tuning
            for idx in intervals.indices {
                let hz = userF0 * intervals[idx].ratio
                let cents = 1200 * log2(tunerData.pitch.measurement.value / hz)
                let isMatch = abs(cents) <= tuningCents
                if isMatch {
                    intervalParticleLevels[idx] = min(intervalParticleLevels[idx] + 0.09, 1.0)
                } else {
                    intervalParticleLevels[idx] = max(intervalParticleLevels[idx] - 0.11, 0.1)
                }
            }
        }
        .padding()
    }
}

// ---- Planetary Interval Visualizer (Reusable) ----
struct PlanetaryIntervalView: View {
    let f0: Double
    let liveHz: Double
    let intervals: [(name: String, ratio: Double, color: Color)]
    @Binding var particleLevels: [Double]
    let maxRadius: CGFloat
    let ringThickness: CGFloat
    let asteroidMax: Int
    let tuningCents: Double

    func ringRadius(_ idx: Int) -> CGFloat {
        let minR: CGFloat = 50
        let step: CGFloat = 27
        return minR + CGFloat(idx) * step
    }
    func isMatching(_ idx: Int) -> Bool {
        guard idx < intervals.count else { return false }
        let hz = f0 * intervals[idx].ratio
        let cents = 1200 * log2(liveHz / hz)
        return abs(cents) <= tuningCents
    }
    func noteName(for freq: Double) -> String {
        guard freq > 0 else { return "--" }
        let noteNames = ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
        let midi = Int(round(69 + 12 * log2(freq / 440)))
        let note = noteNames[(midi + 120) % 12]
        let octave = (midi / 12) - 1
        return "\(note)\(octave)"
    }
    func orbitAngle(to targetHz: Double, liveHz: Double) -> Double {
        let cents = 1200 * log2(liveHz / targetHz)
        return (cents / 1200) * 2 * .pi
    }
    func closestIntervalIdx() -> Int {
        intervals.enumerated().min(by: { abs((f0 * $0.element.ratio) - liveHz) < abs((f0 * $1.element.ratio) - liveHz) })?.offset ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            ZStack {
                ForEach(intervals.indices, id: \.self) { idx in
                    if idx < particleLevels.count {
                        let interval = intervals[idx]
                        let hz = f0 * interval.ratio
                        let radius = ringRadius(idx)
                        let match = isMatching(idx)
                        let particles = Int(particleLevels[idx] * Double(asteroidMax))

                        // RING
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        interval.color.opacity(match ? 0.65 : 0.20),
                                        .white.opacity(match ? 0.7 : 0.09)
                                    ]),
                                    center: .center
                                ),
                                lineWidth: match ? ringThickness * 1.7 : ringThickness
                            )
                            .frame(width: radius * 2, height: radius * 2)
                            .animation(.easeInOut(duration: 0.4), value: match)
                            .opacity(match ? 1 : 0.85)

                        // Pitch+interval name on ring
                        Text("\(interval.name): \(noteName(for: hz))")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white.opacity(match ? 0.99 : 0.5))
                            .background(.black.opacity(0.45))
                            .offset(x: 0, y: -radius-16)
                            .animation(.easeInOut(duration: 0.4), value: match)

                        // ASTEROID PARTICLES
                        RingParticlesView(radius: radius, active: match, count: particles, center: center, color: interval.color)
                            .opacity(match ? 1.0 : 0.18)
                    }
                }

                // ---- GLOWING SUN (f₀) ----
                let sunMatch = isMatching(0)
                Circle()
                    .fill(sunMatch ? Color.yellow : Color.yellow.opacity(0.89))
                    .frame(width: 38, height: 38)
                    .shadow(color: Color.yellow.opacity(sunMatch ? 1.0 : 0.36), radius: sunMatch ? 28 : 14)
                    .overlay(
                        VStack(spacing: 2) {
                            Text("f₀: \(noteName(for: f0))")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.black)
                            if sunMatch {
                                Text("✨")
                                    .font(.title)
                            }
                        }
                    )
                    .scaleEffect(sunMatch ? 1.11 : 1.0)
                    .animation(.easeInOut(duration: 0.35), value: sunMatch)

                // ---- LIVE PLANET ----
                let closestIdx = closestIntervalIdx()
                let r = ringRadius(closestIdx)
                let angle = orbitAngle(to: f0 * intervals[closestIdx].ratio, liveHz: liveHz)
                PlanetView(
                    radius: r,
                    angle: angle,
                    liveHz: liveHz,
                    color: .purple,
                    note: noteName(for: liveHz)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: angle)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.black.opacity(0.97))
            .clipShape(Circle())
            .shadow(radius: 18)
        }
    }
}

// ---- Ring Particles (Saturn Rocks) ----
struct RingParticlesView: View {
    let radius: CGFloat
    let active: Bool
    let count: Int
    let center: CGPoint
    let color: Color
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { idx in
                let angle = Double(idx) / Double(max(1,count)) * 2 * .pi
                let x = radius * CGFloat(cos(angle))
                let y = radius * CGFloat(sin(angle))
                Circle()
                    .fill(color.opacity(active ? 0.52 : 0.19))
                    .frame(width: active ? 6 : 2.5, height: active ? 6 : 2.5)
                    .offset(x: x, y: y)
                    .blur(radius: active ? 0.8 : 1.7)
                    .animation(.easeInOut(duration: 0.4), value: active)
            }
        }
    }
}

// ---- Live Planet ----
struct PlanetView: View {
    let radius: CGFloat
    let angle: Double
    let liveHz: Double
    let color: Color
    let note: String
    var body: some View {
        let x = radius * CGFloat(cos(angle))
        let y = radius * CGFloat(sin(angle))
        return Circle()
            .fill(color.opacity(0.86))
            .frame(width: 24, height: 24)
            .shadow(color: color.opacity(0.5), radius: 9, x: 0, y: 0)
            .overlay(
                Text(note)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
            .offset(x: x, y: y)
            .animation(.interpolatingSpring(stiffness: 90, damping: 21), value: angle)
    }
}

