import SwiftUI

struct PlanetaryPitchView: View {
    let f0: Double
    let liveHz: Double

    // Each interval: (label, Hz, color)
    var intervals: [(name: String, freq: Double, color: Color)] {
        let phi = 1.61803398875
        return [
            ("f₀",  f0,            .yellow),
            ("M2",  f0 * 9/8,      .green),
            ("M3",  f0 * 5/4,      .red),
            ("P4",  f0 * 4/3,      .cyan),
            ("P5",  f0 * 3/2,      .orange),
            ("M6",  f0 * 5/3,      .purple),
            ("M7",  f0 * 15/8,     .blue),
            ("8ve", f0 * 2,        .mint),
            ("φ",   f0 * phi,      .pink) // Golden ratio, optional
        ]
    }

    @State private var particleLevels: [Double] = []

    let maxRadius: CGFloat = 120
    let ringThickness: CGFloat = 10
    let asteroidMax: Int = 36

    // Tuning threshold (cents)
    let tuningCents: Double = 25

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            ZStack {
                ForEach(intervals.indices, id: \.self) { idx in
                    // --- GUARD: avoid out of bounds ---
                    if idx < particleLevels.count {
                        let interval = intervals[idx]
                        let radius = ringRadius(idx)
                        let match = isMatching(interval.freq)
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
                        Text("\(interval.name): \(noteName(for: interval.freq))")
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
                let sunMatch = isMatching(f0)
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
                let angle = orbitAngle(to: intervals[closestIdx].freq, liveHz: liveHz)
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
        .frame(width: maxRadius * 2.3, height: maxRadius * 2.3)
        .onAppear {
            syncParticleLevels()
        }
        .onChange(of: f0) { _ in
            syncParticleLevels()
        }
        .onReceive(timer) { _ in
            accumulateParticles()
        }
    }

    // MARK: - Helpers

    func ringRadius(_ idx: Int) -> CGFloat {
        let minR: CGFloat = 50
        let step: CGFloat = 27
        return minR + CGFloat(idx) * step
    }
    func cents(from refHz: Double, to targetHz: Double) -> Double {
        guard refHz > 0, targetHz > 0 else { return 0 }
        return 1200 * log2(refHz / targetHz)
    }
    func isMatching(_ intervalHz: Double) -> Bool {
        abs(cents(from: liveHz, to: intervalHz)) <= tuningCents
    }
    func closestIntervalIdx() -> Int {
        intervals.enumerated().min(by: { abs($0.element.freq - liveHz) < abs($1.element.freq - liveHz) })?.offset ?? 0
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
        let cents = cents(from: liveHz, to: targetHz)
        return (cents/1200) * 2 * .pi
    }
    // Animate accumulation of particles
    func accumulateParticles() {
        // Defensive check!
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

