//
//  TunerStreak.swift
//  Chromatic
//
//  Created by David Nyman on 7/11/25.
//

import SwiftUI
import Foundation

// MARK: - Supporting Types for TunerStreak

struct TunerStreakStats {
    var minPitch: Double
    var maxPitch: Double
    var avgPitch: Double
    var stdDev: Double
    var uniquePitchCount: Int
    var outlierCount: Int
    var amplitude: Double
    var sessionDuration: Double
    var inTunePercent: Double
}

struct TunerStreakLayer: Identifiable {
    let id = UUID()
    let milestoneIndex: Int
    let size: CGFloat
    let color: Color
    let animationStrength: CGFloat
    let animationFrequency: CGFloat
    let animationDuration: Double
}

// MARK: - Chroma Color Function

func tunerStreakChromaColor(for pitch: Double, saturation: Double = 0.38, brightness: Double = 0.92) -> Color {
    guard pitch > 0 else { return Color.gray }
    let midi = 69 + 12 * log2(pitch / 440)
    let idx  = (Int(round(midi)) % 12 + 12) % 12
    let hue  = Double(idx) / 12.0
    return Color(hue: hue, saturation: saturation, brightness: brightness)
}

// MARK: - Unique Shape

struct TunerStreakVoicePrintShape: Shape {
    var baseRadius: CGFloat
    var waviness: CGFloat
    var lobes: Int
    var inTunePercent: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = 360
        let angleStep = (2 * .pi) / CGFloat(points)
        
        var path = Path()
        for i in 0..<points {
            let angle = angleStep * CGFloat(i)
            let lobeEffect = sin(angle * CGFloat(lobes))
            let smoothness = CGFloat(inTunePercent)
            let radius = baseRadius + (lobeEffect * smoothness)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct TunerStreakWavingCircleBorder: View {
    var strength: CGFloat
    var frequency: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var animationDuration: Double
    var highlighted: Bool = false
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TunerStreakVoicePrintShape(
            baseRadius: 0.5 * 120,
            waviness: frequency * strength,
            lobes: Int(frequency),
            inTunePercent: 0.5 + 0.5 * CGFloat(sin(Double(phase)))
        )
        .stroke(
            color.opacity(highlighted ? 1.0 : 0.8),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
        .onAppear {
            withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

// MARK: - Main TunerStreak View

struct TunerStreak: View {
    // -- Inputs
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    
    // -- State
    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @State private var countdown: Int?
    let countdownSeconds = 3
    @State private var recordingStartedAt: Date?
    
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78
    
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var updateCount: Int = 0
    private let updatesPerPoint: Int = 5
    private let inTuneThreshold: Double = 5.0
    
    @State private var solidifiedLayers: [TunerStreakLayer] = []
    @State private var milestoneRings: [Int] = []
    
    private let coreBaseSize: CGFloat = 40
    private let coreGrowthFactor: CGFloat = 6.5
    
    @State private var rotationAngle: Double = 0
    @State private var pulse = false
    
    @State private var showingProfileSelector = false
    
    // --- NEW/CHANGED STATE FOR RING ANIMATION ---
    @State private var ringRotation: Double = 0
    @State private var isStreaking: Bool = false
    @State private var ringAnimating: Bool = false
    @State private var lastStreakValue: Int = 0
    
    private func startRingAnimation() {
        guard !ringAnimating else { return }
        ringAnimating = true
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            ringRotation += 360
        }
    }
    private func stopRingAnimation() {
        ringAnimating = false
        // Do not reset ringRotation so the ring "freezes" at its current spot
    }
    
    // -- Preview/Mock Colors
    private let spectrumColors: [Color] = (0..<12).map { tunerStreakChromaColor(for: 220 * pow(2, Double($0)/12.0)) }
    
    // -- "Work in progress" stats using recent pitch window
    private var liveVoicePrintStats: TunerStreakStats {
        let window = 36
        let values = tunerData.recordedPitches.suffix(window)
        guard !values.isEmpty else {
            return TunerStreakStats(
                minPitch: userF0, maxPitch: userF0, avgPitch: userF0, stdDev: 0,
                uniquePitchCount: 1, outlierCount: 0,
                amplitude: tunerData.amplitude, sessionDuration: 1, inTunePercent: 0
            )
        }
        let minP = values.min() ?? userF0
        let maxP = values.max() ?? userF0
        let avgP = values.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(values.reduce(0) { $0 + pow($1 - avgP, 2) } / Double(values.count))
        let uniqueP = Set(values.map { Int($0) }).count
        let inTuneC = values.filter { abs($0 - userF0) <= inTuneThreshold }.count
        return TunerStreakStats(
            minPitch: minP,
            maxPitch: maxP,
            avgPitch: avgP,
            stdDev: stdDev,
            uniquePitchCount: uniqueP,
            outlierCount: 0,
            amplitude: tunerData.amplitude,
            sessionDuration: Double(window) / 18.0,
            inTunePercent: Double(inTuneC) / Double(window) * 100
        )
    }
    
    var body: some View {
        VStack(spacing: 22) {
            // Profile selection bar
            
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
            ZStack {
                
                TuningOverlapCirclesView(
                    targetF0: userF0,
                    liveF0: tunerData.pitch.measurement.value
                )
                
                // --- PROGRESS RING (grows & spins only while streaking) ---
                let progressLevel = currentStreak / 10
                let ringBaseSize: CGFloat = 220
                let ringSize = ringBaseSize + CGFloat(progressLevel) * 16
                
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.white, tunerStreakChromaColor(for: liveVoicePrintStats.avgPitch, saturation: 0.6), .white]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: CGFloat(min(Double(currentStreak % 10) / 10.0, 1.0)), lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90 + ringRotation))
                    .frame(width: ringSize, height: ringSize)
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 0.4), value: currentStreak)
    

                
                // "Work-in-progress" liquid voice print
                //                TunerStreakVoicePrintShape(
                //                    baseRadius: 68 + CGFloat(liveVoicePrintStats.amplitude * 45),
                //                    waviness: 1 + CGFloat(liveVoicePrintStats.stdDev * 2),
                //                    lobes: (liveVoicePrintStats.uniquePitchCount),
                //                    inTunePercent: 0.5 - (liveVoicePrintStats.inTunePercent / 200)
                //                )
                //                .stroke(
                //                    tunerStreakChromaColor(for: liveVoicePrintStats.avgPitch, saturation: 0.8)
                //                        .opacity(0.9),
                //                    lineWidth: 1
                //                )
                //                WaveCircleBorder(strength: abs(userF0/tunerData.pitch.measurement.value*7), frequency: CGFloat(tunerData.pitch.measurement.value / 10), lineWidth: 4 * tunerData.amplitude, color:  tunerStreakChromaColor(for: liveVoicePrintStats.minPitch, saturation: 0.7), animationDuration: 3, autoreverses: false, height: 140)
                Circle().stroke(Color.white, lineWidth: CGFloat(currentStreak/7))
                WaveCircleBorder(strength: abs(userF0/tunerData.pitch.measurement.value*3), frequency: CGFloat(9), lineWidth: 20 * tunerData.amplitude, color:  tunerStreakChromaColor(for: tunerData.pitch.measurement.value, saturation: 0.9), animationDuration: 2, autoreverses: false, height: 340)
                WaveCircleBorder(strength: abs(userF0/tunerData.pitch.measurement.value*1), frequency: CGFloat(7), lineWidth: CGFloat(currentStreak/7), color:  tunerStreakChromaColor(for: tunerData.pitch.measurement.value, saturation: 0.5), animationDuration: 0.4, autoreverses: false, height: 200).opacity(0.3)
                
                
                //                WaveCircleBorder(strength: 1 * tunerData.amplitude, frequency: CGFloat(tunerData.pitch.measurement.value / 10), lineWidth: 4 * tunerData.amplitude, color:  tunerStreakChromaColor(for: liveVoicePrintStats.avgPitch, saturation: 0.2), animationDuration: 3, autoreverses: false, height: 240)
                
                //                .shadow(color: tunerStreakChromaColor(for: liveVoicePrintStats.avgPitch, saturation: 0.3).opacity(0.2), radius: 12)
                //                .rotationEffect(.degrees(rotationAngle))
                //                .animation(.linear(duration: 11).repeatForever(autoreverses: false), value: rotationAngle)
                
                // -- Solidified streak rings --
                //                ForEach(solidifiedLayers) { layer in
                //                    TunerStreakWavingCircleBorder(
                //                        strength: layer.animationStrength,
                //                        frequency: layer.animationFrequency,
                //                        lineWidth: 4.2,
                //                        color: layer.color,
                //                        animationDuration: layer.animationDuration
                //                    )
                //                    .frame(width: layer.size, height: layer.size)
                //                    .opacity(0.45 + 0.4 * (CGFloat(layer.milestoneIndex + 1) / CGFloat(solidifiedLayers.count + 1)))
                //                    .rotationEffect(.degrees(rotationAngle / Double(layer.milestoneIndex + 2)))
                //                }
                // -- Milestone ring at every 10 --
                //                ForEach(milestoneRings, id: \.self) { milestone in
                //                    Circle()
                //                        .stroke(
                //                            LinearGradient(
                //                                colors: [.yellow, .orange, .yellow],
                //                                startPoint: .leading, endPoint: .trailing
                //                            ),
                //                            lineWidth: 11
                //                        )
                //                        .frame(width: 228, height: 228)
                //                        .shadow(color: .yellow.opacity(0.18), radius: 15)
                //                        .scaleEffect(pulse ? 1.09 : 1.0)
                //                        .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: pulse)
                //                }
                // -- Active, growing core --
                //                let coreSize = coreBaseSize + CGFloat(currentStreak) * coreGrowthFactor
                //                let coreColor = tunerStreakChromaColor(for: liveVoicePrintStats.avgPitch, saturation: 0.62)
                //                TunerStreakWavingCircleBorder(
                //                    strength: 1.4 + CGFloat(currentStreak) * 0.09,
                //                    frequency: 10 + CGFloat(currentStreak) * 0.008,
                //                    lineWidth: 2.6 + CGFloat(currentStreak) * 0.008,
                //                    color: coreColor,
                //                    animationDuration: max(0.6, 1.2 - Double(currentStreak) * 0.05),
                //                    highlighted: abs(tunerData.pitch.measurement.value - userF0) <= inTuneThreshold
                //                )
                //                .frame(width: coreSize, height: coreSize)
                //                .scaleEffect(pulse ? 1.04 : 0.93)
                //                .animation(.spring(response: 0.6, dampingFraction: 0.58), value: coreSize)
                //                .shadow(color: coreColor.opacity(0.13), radius: 16)
                //
                // -- Centered countdown overlay --
                if let c = countdown {
                    Text("\(c)")
                        .font(.system(size: 65, weight: .black, design: .rounded))
                        .foregroundColor(.cyan)
                        .shadow(color: .black.opacity(0.6), radius: 7)
                        .transition(.scale.combined(with: .opacity))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                }
            }
            .frame(width: 200, height: 200)
            .padding(.top)
            .onAppear {
                if isStreaking {
                    startRingAnimation()
                }
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }
            .onChange(of: tunerData.pitch.measurement.value) { newPitch in
                guard tunerData.isRecording, countdown == nil else { return }
                updateCount += 1
                let isInTune = abs(newPitch - userF0) <= inTuneThreshold
                
                if isInTune, updateCount % updatesPerPoint == 0 {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                    if currentStreak > lastStreakValue {
                        lastStreakValue = currentStreak
                        isStreaking = true
                        ringRotation = ringRotation.truncatingRemainder(dividingBy: 360)
                        startRingAnimation()
                    }                    // --- milestone and layer logic ---
                    if currentStreak > 0 {
                        let outerSize = 228 + CGFloat(currentStreak) * 3
                        let lineW = 11 + CGFloat(currentStreak) * 10.2
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow, .orange, .yellow],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                lineWidth: lineW
                            )
                            .frame(width: outerSize, height: outerSize)
                            .shadow(color: .yellow.opacity(0.98), radius: 15)
                            .scaleEffect(2 + CGFloat(currentStreak) * 0.02)
                            .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: pulse)
                    }
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
                        TunerStreakLayer(
                            milestoneIndex: streakIndex,
                            size: layerSize,
                            color: layerColor,
                            animationStrength: 1.0,
                            animationFrequency: layerFreq,
                            animationDuration: layerAnimDuration
                        )
                    )
                } else if !isInTune {
                    // Pause/freeze animation when out of tune
                    isStreaking = false
                    stopRingAnimation()
                }
            }
            
            // -- Pitch/Streak Text
            VStack(spacing: 8) {
                
                Text("Target f₀: \(String(format: "%.2f", userF0)) Hz")
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                Text("Live Pitch: \(String(format: "%.2f", tunerData.pitch.measurement.value)) Hz")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.7), radius: 2)
                if currentStreak == 0 {
                    Text("Let’s Get Started!")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("🔥 Streak: \(currentStreak) 🔥")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(currentStreak > 0 ? .yellow : .gray)
                        .shadow(color: currentStreak > 0 ? .orange.opacity(0.8) : .clear, radius: 5)
                        .animation(.spring(), value: currentStreak)
                }
                if bestStreak > 0 {
                    Text("Best: \(bestStreak)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.top, 5)
            
            // -- Controls
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
    
    // MARK: – Helpers
    
    private func toggleRecording() {
        if tunerData.isRecording {
            tunerData.stopRecording()
            let duration = Date().timeIntervalSince(recordingStartedAt ?? Date())
            sessionStats = tunerData.calculateStatisticsExtended(duration: max(0, duration))
            showStatsModal = true
            recordingStartedAt = nil
            // --- Reset streak animation state on stop ---
            isStreaking = false
            ringRotation = 0
            lastStreakValue = 0
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
                    // --- Reset streak animation state on start ---
                    isStreaking = false
                    ringRotation = 0
                    lastStreakValue = 0
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
        milestoneRings.removeAll()
        // --- Reset streak animation state on clear ---
        isStreaking = false
        ringRotation = 0
        lastStreakValue = 0
    }
    
    private func syncF0WithProfile() {
        if let f0 = profileManager.currentProfile?.f0 {
            userF0 = f0
        }
    }
}

// MARK: - Preview

extension TunerStreak {
    init(previewStreak: Int) {
        let mock = TunerData(pitch: 100, amplitude: 0.4)
        _tunerData = .constant(mock)
        _modifierPreference = State(initialValue: .preferSharps)
        _selectedTransposition = State(initialValue: 0)
        let layers = (0..<previewStreak).map { idx in
            TunerStreakLayer(
                milestoneIndex: idx,
                size: 40 + CGFloat(idx) * 6.5,
                color: tunerStreakChromaColor(for: 220 * pow(2, Double(idx)/12.0)),
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
            TunerStreak(previewStreak: 9).previewDisplayName("Streak: 9")
            TunerStreak(previewStreak: 29).previewDisplayName("Streak: 29")
            TunerStreak(previewStreak: 39).previewDisplayName("Streak: 39")
            TunerStreak(previewStreak: 49).previewDisplayName("Streak: 49")
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
