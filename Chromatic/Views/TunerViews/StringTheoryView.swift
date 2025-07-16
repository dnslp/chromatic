// StringTheoryView.swift
// Created: 2025-07-09 by David Nyman with ChatGPT

import SwiftUI

// MARK: - Helpers

let spectrumColors: [Color] = [
    .red, .orange, .yellow, .green, .cyan, .blue, .indigo, .purple
]

// Returns how many cents freq1 is above freq2. (0 if identical)
func centsDistance(from freq1: Double, to freq2: Double) -> Double {
    guard freq1 > 0, freq2 > 0 else { return .infinity }
    return 1200 * log2(freq1 / freq2)
}

// MARK: - Shapes & Subviews

struct OrbitPathShape: Shape {
    let radius: CGFloat
    let amplitude: CGFloat
    let phase: CGFloat
    let vibrate: Bool
    var highlighted: Bool = false

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let steps = 200
        let twoPi = CGFloat.pi * 2
        var path = Path()
        for i in 0...steps {
            let pct = CGFloat(i) / CGFloat(steps)
            let angle = pct * twoPi
            // Wobble is bigger if highlighted
            let localAmp = amplitude * (highlighted ? 1.5 : 1)
            let wobble = vibrate ? sin(angle * 6 + phase) * localAmp : 0
            let r = radius + wobble
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}

struct OrbitingPlanet: View {
    let color: Color
    let orbitRadius: CGFloat
    let phase: Double
    let size: CGFloat
    let label: String?
    @Binding var time: Double
    var highlighted: Bool = false
    var isTonic: Bool = false

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let angle = time + phase
            let x = center.x + cos(angle) * orbitRadius
            let y = center.y + sin(angle) * orbitRadius

            ZStack {
                // "Pulse" effect if highlighted (tonic = even more)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                highlighted ? (isTonic ? .yellow : .white) : color,
                                (highlighted ? .white : color).opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 0, endRadius: size * (highlighted ? 2.5 : 2))
                    )
                    .frame(width: highlighted ? size*1.8 : size, height: highlighted ? size*1.8 : size)
                    .scaleEffect(highlighted ? 1.3 : 1)
                    .shadow(color: highlighted ? (isTonic ? .yellow : .white) : color.opacity(0.7),
                            radius: highlighted ? 18 : size*0.7)
                    .overlay(
                        Circle()
                            .stroke(highlighted ? Color.white.opacity(isTonic ? 0.9 : 0.7) : Color.clear,
                                    lineWidth: highlighted ? (isTonic ? 5 : 3) : 0)
                            .scaleEffect(highlighted ? 1.3 : 1)
                            .animation(.spring(), value: highlighted)
                    )
                    .animation(.spring(), value: highlighted)
                if let label = label {
                    Text(label)
                        .font(highlighted ? .system(size: 24, weight: .heavy, design: .rounded) : .caption.bold())
                        .foregroundColor(.white)
                        .shadow(color: highlighted ? .yellow : .clear, radius: 3)
                        .offset(y: size + 10)
                        .animation(.spring(), value: highlighted)
                }
            }
            .position(x: x, y: y)
        }
    }
}

// Animated Waving Aura
struct WavingCircleBorder: View {
    var strength: CGFloat = 1
    var frequency: CGFloat = 2
    var lineWidth: CGFloat = 3
    var color: Color = .green
    var animationDuration: Double = 2
    var highlighted: Bool = false
    var autoreverses: Bool = false

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.13), lineWidth: lineWidth)
            CircleWave(strength: highlighted ? strength*2.2 : strength,
                       frequency: frequency,
                       phase: phase)
                .stroke(highlighted ? .yellow : color, lineWidth: highlighted ? lineWidth * 2 : lineWidth)
                .shadow(color: highlighted ? .yellow : color.opacity(0.4), radius: highlighted ? 20 : 6)
                .animation(
                    Animation.linear(duration: animationDuration)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
        }
        .frame(width: highlighted ? 135 : 110, height: highlighted ? 135 : 110)
        .onAppear { phase = .pi * 2 }
    }
}

// Animated Atomic Countdown
struct AtomicCountdownView: View {
    let countdown: Int
    let total: Int
    let color: Color

    var progress: CGFloat { CGFloat(countdown) / CGFloat(total) }

    var body: some View {
        ZStack {
            // Animated atomic orbits
            ForEach(0..<3) { i in
                Circle()
                    .stroke(color.opacity(0.45), lineWidth: CGFloat(2 + i))
                    .scaleEffect(1 + CGFloat(i) * 0.17)
                    .rotationEffect(.degrees(Double(countdown + i) * 32))
                    .blur(radius: CGFloat(i))
                    .animation(.easeInOut(duration: 0.6), value: countdown)
            }
            // Countdown number
            Text("\(countdown)")
                .font(.system(size: 70, weight: .black, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.6), radius: 9)
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 95, height: 95)
                .opacity(0.9)
        }
        .frame(width: 140, height: 140)
    }
}

// MARK: - Main StringTheoryView

struct StringTheoryView: View {
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

    // User Profile Info
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78

    // Sheet for profile selection
    @State private var showingProfileSelector = false

    // Animation
    @State private var time: Double = 0

    // Diatonic scale: C major intervals (can swap for user mode)
    let scaleDegrees = ["1", "2", "3", "4", "5", "6", "7", "8"]
    let scaleIntervals: [Double] = [0, 2, 4, 5, 7, 9, 11, 12] // semitones

    func frequencies(from base: Double) -> [Double] {
        scaleIntervals.map { base * pow(2, $0 / 12.0) }
    }

    // Returns index of the closest matching scale degree (including tonic) within threshold
    func matchingIndex(pitch: Double, f0: Double, threshold: Double = 28) -> Int? {
        let freqs = frequencies(from: f0)
        for (i, freq) in freqs.enumerated() {
            if abs(centsDistance(from: pitch, to: freq)) < threshold {
                return i
            }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 26) {
            let livePitch = tunerData.pitch.measurement.value
            let highlightIdx = matchingIndex(pitch: livePitch, f0: userF0)
            let isTonic = (highlightIdx == 0)
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
                AtomicCountdownView(countdown: c, total: countdownSeconds, color: .cyan)
                    .transition(.scale)
            }

            // --------- String Theory Visualizer ----------
            ZStack {
                Color.black.ignoresSafeArea(.all)
                GeometryReader { geo in
                    let size = min(geo.size.width, geo.size.height) * 0.95
                    let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                    let minOrbit = size * 0.21
                    let maxOrbit = size * 0.49

                    let livePitch = tunerData.pitch.measurement.value
                    let highlightIdx = matchingIndex(pitch: livePitch, f0: userF0)
                    let isTonic = highlightIdx == 0

                    // --- Orbits ---
                    ForEach(0..<scaleDegrees.count, id: \.self) { i in
                        let pct = CGFloat(i) / CGFloat(scaleDegrees.count-1)
                        let orbitRadius = minOrbit + pct * (maxOrbit - minOrbit)
                        let color = spectrumColors[i % spectrumColors.count]
                        let highlighted = highlightIdx == i

                        OrbitPathShape(
                            radius: orbitRadius,
                            amplitude: 1 * pct,
                            phase: CGFloat(time) * (0.8 + 0.2 * pct),
                            vibrate: true,
                            highlighted: highlighted
                        )
                        .stroke(
                            highlighted ? .white : color.opacity(0.52 + 0.2*pct),
                            lineWidth: highlighted ? 7.8 : 2.2
                        )
                        .shadow(color: highlighted ? .yellow : .clear, radius: highlighted ? 13 : 0)
                        .blur(radius: highlighted ? 0 : 1)
                        .animation(.spring(), value: highlighted)
                        
                    }

                    // --- Orbiting Planets ---
                    ForEach(0..<scaleDegrees.count, id: \.self) { i in
                        let pct = CGFloat(i) / CGFloat(scaleDegrees.count-1)
                        let orbitRadius = minOrbit + pct * (maxOrbit - minOrbit)
                        let color = spectrumColors[i % spectrumColors.count]
                        let highlighted = highlightIdx == i
                        OrbitingPlanet(
                            color: color,
                            orbitRadius: orbitRadius,
                            phase: highlighted ? time : 0, // <--- ONLY highlighted planet rotates!
                            size: 1 + 6 * pct,
                            label: scaleDegrees[i],
                            time: $time,
                            highlighted: highlighted,
                            isTonic: i == 0
                        )
                        .shadow(color: highlighted ? .yellow : .clear, radius: highlighted ? 1 : 0)
                    }

                    // --- Central Nucleus (f₀) ---
                    ZStack {
                        WavingCircleBorder(
                            strength: 1,
                            frequency: 1,
                            lineWidth: 4.0,
                            color: .white,
                            animationDuration: 2,
                            highlighted: isTonic
                            
                        )
                        Circle()
                            .fill(RadialGradient(gradient: Gradient(colors: [.white, .cyan, .blue.opacity(0.45)]),
                                                 center: .center,
                                                 startRadius: 0,
                                                 endRadius: isTonic ? 80 : 54))
                            .frame(width: isTonic ? 105 : 74, height: isTonic ? 105 : 74)
                            .shadow(color: isTonic ? .yellow : .cyan.opacity(0.7), radius: isTonic ? 30 : 20)
                            .overlay(
                                Circle()
                                    .stroke(isTonic ? Color.yellow : .clear, lineWidth: isTonic ? 5 : 0)
                                    .scaleEffect(isTonic ? 1.2 : 1)
                            )
                            .animation(.spring(), value: isTonic)
                    }
                    .position(center)
                }
                .frame(height: 350)


                // Overlay live pitch frequency
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Text("f₀: \(userF0, specifier: "%.2f") Hz")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .blue.opacity(0.7), radius: 3)
                            .scaleEffect(isTonic ? 1.4 : 1)
                            .animation(.spring(), value: isTonic)

                        if let idx = highlightIdx {
                            Text(idx == 0 ? "Tonic!" : "Degree \(scaleDegrees[idx])")
                                .font(.headline)
                                .foregroundColor(idx == 0 ? .yellow : .white)
                                .shadow(color: .yellow.opacity(0.8), radius: 6)
                                .scaleEffect(1.4)
                                .transition(.opacity)
                        }
                    }
                    
                    Text("Live: \(tunerData.pitch.measurement.value, specifier: "%.2f") Hz")
                        .font(.title2)
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan.opacity(0.9), radius: 5)
                    Spacer().frame(height: 0)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 360)
            .cornerRadius(30)
            .padding(.horizontal, 5)
    
            .opacity(countdown == nil ? 1 : 0.21)

            // ------- Recording Controls -------
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
                }) {
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
            ProfileSelectionView(profileManager: profileManager, isPresented: $showingProfileSelector)
        }
        .onAppear {
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
        .padding()
        .background(Color(.black))
    }
}

// MARK: - Preview
struct StringTheoryView_Previews: PreviewProvider {
    static var mockProfileManager: UserProfileManager {
        let manager = UserProfileManager()
        manager.profiles = [
            UserProfile(name: "Soprano", f0: 329.63), // E4
            UserProfile(name: "Tenor", f0: 146.83),   // D3
            UserProfile(name: "Bass", f0: 82.41),     // E2
        ]
        manager.currentProfile = manager.profiles[1]
        return manager
    }

    static var previews: some View {
        Group {
            // In-tune (tonic)
            StringTheoryView(
                tunerData: .constant(TunerData(pitch: 146.83, amplitude: 0.7)),
                modifierPreference: .preferSharps,
                selectedTransposition: 0
            )
            .environmentObject(mockProfileManager)
            .previewDisplayName("Tonic Match")
            .padding()

            // In-tune (5th degree)
            StringTheoryView(
                tunerData: .constant(TunerData(pitch: 220.00, amplitude: 0.6)), // ~perfect 5th above 146.83
                modifierPreference: .preferSharps,
                selectedTransposition: 0
            )
            .environmentObject(mockProfileManager)
            .previewDisplayName("Degree Match (5th)")
            .padding()

            // Out of tune
            StringTheoryView(
                tunerData: .constant(TunerData(pitch: 160.00, amplitude: 0.4)),
                modifierPreference: .preferFlats,
                selectedTransposition: 0
            )
            .environmentObject(mockProfileManager)
            .previewDisplayName("No Match")
            .padding()

            // High f0 (Soprano)
            StringTheoryView(
                tunerData: .constant(TunerData(pitch: 349.23, amplitude: 0.4)), // F4, close to Soprano f0
                modifierPreference: .preferSharps,
                selectedTransposition: 0
            )
            .environmentObject({
                let manager = UserProfileManager()
                manager.profiles = [UserProfile(name: "Soprano", f0: 329.63)]
                manager.currentProfile = manager.profiles.first
                return manager
            }())
            .previewDisplayName("Soprano Tonic Match")
            .padding()

            // Low f0 (Bass)
            StringTheoryView(
                tunerData: .constant(TunerData(pitch: 82.41, amplitude: 0.7)), // E2
                modifierPreference: .preferSharps,
                selectedTransposition: 0
            )
            .environmentObject({
                let manager = UserProfileManager()
                manager.profiles = [UserProfile(name: "Bass", f0: 82.41)]
                manager.currentProfile = manager.profiles.first
                return manager
            }())
            .previewDisplayName("Bass Tonic Match")
            .padding()
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
