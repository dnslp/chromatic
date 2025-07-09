import SwiftUI

struct CreativeTunerView: View {
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

    // Planetary view properties
    @State private var particleLevels: [Double] = []
    let maxRadius: CGFloat = 120
    let ringThickness: CGFloat = 10
    let asteroidMax: Int = 36
    let tuningCents: Double = 25
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var intervals: [(name: String, freq: Double, color: Color)] {
        let phi = 1.61803398875
        return [
            ("f₀",  userF0,            .yellow),
            ("M2",  userF0 * 9/8,      .green),
            ("M3",  userF0 * 5/4,      .red),
            ("P4",  userF0 * 4/3,      .cyan),
            ("P5",  userF0 * 3/2,      .orange),
            ("M6",  userF0 * 5/3,      .purple),
            ("M7",  userF0 * 15/8,     .blue),
            ("8ve", userF0 * 2,        .mint),
            ("φ",   userF0 * phi,      .pink) // Golden ratio, optional
        ]
    }

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

            // --------- COUNTDOWN TIMER ----------
            if let c = countdown {
                Text("\(c)")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.vertical, 12)
                    .transition(.scale)
            }

            // ------- Visual Section -------
            PlanetaryIntervalView(
                f0: userF0,
                liveHz: tunerData.pitch.measurement.value,
                intervals: intervals,
                particleLevels: $particleLevels,
                maxRadius: maxRadius,
                ringThickness: ringThickness,
                asteroidMax: asteroidMax,
                tuningCents: tuningCents
            )
            .opacity(countdown == nil ? 1 : 0.25) // Fade during countdown
            .padding(.top)

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
                // Disable the button during countdown, unless you're stopping
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
                .disabled(countdown != nil) // Lock out while countdown
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
            syncParticleLevels() // Initial sync
        }
        .onChange(of: profileManager.currentProfile) { newProfile in
            if let newF0 = newProfile?.f0, userF0 != newF0 {
                userF0 = newF0
            }
            syncParticleLevels() // Sync when profile changes
        }
        .onReceive(timer) { _ in
            accumulateParticles()
        }
        .padding()
    }

    // MARK: - Planetary View Helper Functions
    func cents(from refHz: Double, to targetHz: Double) -> Double {
        guard refHz > 0, targetHz > 0 else { return 0 }
        return 1200 * log2(refHz / targetHz)
    }

    func isMatching(_ intervalHz: Double) -> Bool {
        abs(cents(from: tunerData.pitch.measurement.value, to: intervalHz)) <= tuningCents
    }

    func accumulateParticles() {
        if particleLevels.count != intervals.count {
            syncParticleLevels()
        }
        for idx in intervals.indices {
            let isMatch = isMatching(intervals[idx].freq)
            if isMatch {
                particleLevels[idx] = min(particleLevels[idx] + 0.09, 1.0)
            } else {
                particleLevels[idx] = max(particleLevels[idx] - 0.11, 0.1)
            }
        }
    }

    func syncParticleLevels() {
        particleLevels = Array(repeating: 0.1, count: intervals.count)
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
    let distance: Double // Cents away from target, positive or negative

    var body: some View {
        let x = radius * CGFloat(cos(angle))
        let y = radius * CGFloat(sin(angle))
        // Adjust opacity based on distance: closer is more opaque
        let maxOpacity = 0.95
        let minOpacity = 0.4
        let distanceThreshold: Double = 50 // Cents beyond which opacity is minOpacity
        let opacity = maxOpacity - (abs(distance) / distanceThreshold) * (maxOpacity - minOpacity)
        let clampedOpacity = max(minOpacity, min(maxOpacity, opacity))

        return Circle()
            .fill(color.opacity(clampedOpacity))
            .frame(width: 24, height: 24)
            .shadow(color: color.opacity(clampedOpacity * 0.7), radius: 9, x: 0, y: 0)
            .overlay(
                Text(note)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
            .offset(x: x, y: y)
            .animation(.easeInOut(duration: 0.5), value: angle) // Changed to easeInOut
    }
}

// ---- Planetary Interval Visualizer (Reusable) ----
struct PlanetaryIntervalView: View {
    let f0: Double
    let liveHz: Double
    let intervals: [(name: String, freq: Double, color: Color)] // Changed ratio to freq
    @Binding var particleLevels: [Double]
    let maxRadius: CGFloat
    let ringThickness: CGFloat
    let asteroidMax: Int
    let tuningCents: Double

    // State for sun pulsing animation
    @State private var isSunPulsing: Bool = false

    func ringRadius(_ idx: Int) -> CGFloat {
        let minR: CGFloat = 50
        let step: CGFloat = 27
        return minR + CGFloat(idx) * step
    }

    func cents(from refHz: Double, to targetHz: Double) -> Double {
        guard refHz > 0, targetHz > 0 else { return 0 }
        return 1200 * log2(refHz / targetHz)
    }

    func isMatching(_ intervalHz: Double) -> Bool { // Changed parameter to intervalHz
        abs(cents(from: liveHz, to: intervalHz)) <= tuningCents
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
        let centsVal = cents(from: liveHz, to: targetHz) // Renamed to avoid conflict
        return (centsVal/1200) * 2 * .pi
    }

    func closestIntervalIdx() -> Int {
        intervals.enumerated().min(by: { abs($0.element.freq - liveHz) < abs($1.element.freq - liveHz) })?.offset ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            ZStack {
                ForEach(intervals.indices, id: \.self) { idx in
                    if idx < particleLevels.count { // Ensure particleLevels is populated
                        let interval = intervals[idx]
                        let radius = ringRadius(idx)
                        let match = isMatching(interval.freq) // Use interval.freq
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
                        Text("\(interval.name): \(noteName(for: interval.freq))") // Use interval.freq
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
                let sunMatch = isMatching(f0) // Match against f0
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
                    .scaleEffect(sunMatch ? (isSunPulsing ? 1.15 : 1.11) : (isSunPulsing ? 1.04 : 1.0))
                    .animation(.easeInOut(duration: 0.35), value: sunMatch) // Animation for match change
                    .onAppear {
                        // Add a slight delay to ensure the view is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                isSunPulsing.toggle()
                            }
                        }
                    }
                    // Keep the existing animation for when the sunMatch state changes
                    // The pulsing animation will be layered on top of this.

                // ---- LIVE PLANET ----
                let closestIdx = closestIntervalIdx()
                // Ensure intervals is not empty and closestIdx is valid before accessing
                if !intervals.isEmpty && closestIdx < intervals.count {
                    let closestIntervalFreq = intervals[closestIdx].freq
                    let r = ringRadius(closestIdx)
                    let angle = orbitAngle(to: closestIntervalFreq, liveHz: liveHz)
                    let distanceInCents = cents(from: liveHz, to: closestIntervalFreq)
                    PlanetView(
                        radius: r,
                        angle: angle,
                        liveHz: liveHz,
                        color: .purple,
                        note: noteName(for: liveHz),
                        distance: distanceInCents
                    )
                    .animation(.easeInOut(duration: 0.5), value: angle) // Ensure this animation matches the one in PlanetView if it was also updated
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.black.opacity(0.97))
            .clipShape(Circle())
            .shadow(radius: 18)
        }
    }
}


// Example preview (requires sample TunerData/UserProfileManager in your project)
struct CreativeTunerView_Previews: PreviewProvider {
    static var previews: some View {
        CreativeTunerView(
            tunerData: .constant(TunerData(pitch: 220, amplitude: 0.4)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .environmentObject(UserProfileManager())
        .previewLayout(.sizeThatFits)
    }
}
