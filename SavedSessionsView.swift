import SwiftUI
import AVFoundation

// MARK: - Main View

struct SavedSessionsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: SessionData?
    @State private var expandedDays: Set<Date> = [] // Explicitly type for clarity

    @State private var showingToneSettings = false

    // Group sessions by day (ignoring time)
    private var sessionsByDay: [(day: Date, sessions: [SessionData])] {
        let grouped = Dictionary(grouping: sessionStore.sessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
    }

    // Format for the group header
    private func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationView {

            List {
                if sessionStore.sessions.isEmpty {
                    Text("No saved sessions yet.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(sessionsByDay, id: \.day) { (day, sessions) in
                        Section {
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedDays.contains(day) },
                                    set: { expanded in
                                        if expanded { expandedDays.insert(day) }
                                        else { expandedDays.remove(day) }
                                    }
                                ),
                                content: {
                                    ForEach(sessions) { session in
                                        SessionRowView(session: session)
                                            .swipeActions {
                                                Button(role: .destructive) {
                                                    self.sessionToDelete = session
                                                    self.showingDeleteAlert = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                    .onDelete { offsets in
                                        let sessionIDsToDelete = offsets.map { sessions[$0].id }
                                        for id in sessionIDsToDelete {
                                            sessionStore.deleteSession(id: id)
                                        }
                                    }
                                },
                                label: {
                                    HStack {
                                        Text(formattedDay(day))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        // Badge for number of sessions
                                        Text("\(sessions.count)")
                                            .font(.subheadline.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .toolbar {
                // ...existing items... (This was a comment in original, might be empty or might be merged with below)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingToneSettings = true
                    } label: {
                        Label("Tone Settings", systemImage: "slider.horizontal.3")
                    }
                }
                 // Merging the two toolbars from original code
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sessionStore.sessions.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { // This is a second item for .navigationBarTrailing
                    if !sessionStore.sessions.isEmpty {
                        Menu {
                            Button("Expand All") {
                                expandedDays = Set(sessionsByDay.map { $0.day })
                            }
                            Button("Collapse All") {
                                expandedDays = []
                            }
                        } label: {
                            Label("Options", systemImage: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingToneSettings) {
                TonePlayerControlPanel()
                    .environmentObject(ToneSettingsManager.shared) // This is the key change for this step
            }
            .navigationTitle("Saved Sessions")
            // .toolbar { // This was a duplicate .toolbar modifier, merged above
            // }
            .alert("Delete Session?", isPresented: $showingDeleteAlert, presenting: sessionToDelete) { sessionDetail in
                Button("Delete", role: .destructive) {
                    if let id = sessionToDelete?.id { // Ensure sessionToDelete is not nil
                        sessionStore.deleteSession(id: id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { sessionDetail in
                Text("Are you sure you want to delete the session from \(formattedDate(sessionDetail.date))? This action cannot be undone.")
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Session Row with Sparkline Playback

private struct SessionRowView: View {
    @EnvironmentObject var toneSettings: ToneSettingsManager // Added
    let session: SessionData
    @StateObject private var tonePlayer = TonePlayer() // Assuming TonePlayer is defined
    @State private var showStats = false
    @State private var isPlaying = false
    @State private var playbackChunks: [(Double, Int)] = []
    @State private var playbackChunkIndex: Int = 0
    @State private var playbackTimer: Timer? = nil

    // MARK: - Sparkline Tap/Playback

    private func chunkPitches(_ values: [Double], tolerance: Double = 7.0) -> [(freq: Double, length: Int)] {
        guard !values.isEmpty else { return [] }
        var result: [(Double, Int)] = []
        var currentFreq = values[0]
        var count = 1
        for val in values.dropFirst() {
            if abs(val - currentFreq) <= tolerance {
                count += 1
            } else {
                result.append((currentFreq, count))
                currentFreq = val
                count = 1
            }
        }
        result.append((currentFreq, count))
        return result
    }

    private func startPlayback() {
        guard !session.values.isEmpty else { return }
        isPlaying = true
        playbackChunks = chunkPitches(session.values, tolerance: 7.0)
        playbackChunkIndex = 0
        playbackTimer?.invalidate()
        playNextChunk()
    }

    private func playNextChunk() {
        guard playbackChunkIndex < playbackChunks.count else {
            stopPlayback()
            return
        }
        let (freq, count) = playbackChunks[playbackChunkIndex]
        let segmentDuration = Double(count) * 0.055 // Assuming 0.055s per data point for duration
        if freq > 30 { // Play only if frequency is reasonable
            tonePlayer.play(
                frequency: freq,
                duration: segmentDuration,
                amplitudes: toneSettings.harmonicAmplitudes,
                attack: 0.01, // Default attack
                release: 0.05  // Default release
            )
        }
        playbackChunkIndex += 1
        playbackTimer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: false) { _ in
            playNextChunk()
        }
    }

    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        playbackChunkIndex = 0
        playbackChunks = []
        tonePlayer.stop()
    }

    // MARK: - Info Display

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var durationString: String {
        let totalSeconds = Int(max(0, session.duration))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var stats: PitchStatistics { session.statistics }

    // MARK: - View Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date: \(dateString)").bold()
                    Text("Duration: \(durationString)").bold()
                    Text("Profile: \(session.profileName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let timeline = session.chakraTimeline {
                    // Assuming PitchChakraTimelineView is defined elsewhere
                    // For now, using a placeholder if not available
                    // PitchChakraTimelineView(pitches: timeline.pitches)
                    //     .frame(height: 48)
                    //     .padding(.top, 6)
                    Text("Chakra Timeline Placeholder") // Placeholder
                        .frame(height: 48)
                        .padding(.top, 6)
                }
                if !session.values.isEmpty {
                    ZStack {
                        Sparkline(data: session.values)
                            .stroke(isPlaying ? Color.green : Color.accentColor, lineWidth: 2)
                            .frame(width: 100, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemBackground)) // Use systemBackground for adaptability
                            )
                            .padding(.leading, 8)
                            .onTapGesture {
                                if isPlaying {
                                    stopPlayback()
                                } else {
                                    startPlayback()
                                }
                            }
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                    .foregroundColor(isPlaying ? .red : .accentColor)
                                    .opacity(0.88)
                                    .padding(.top, 2)
                                Spacer()
                            }
                        }
                        .frame(width: 100, height: 32)
                        .allowsHitTesting(false)
                    }
                    .animation(.easeInOut(duration: 0.2), value: isPlaying)
                }
            }

            Divider().padding(.vertical, 2)

            DisclosureGroup("Show Stats", isExpanded: $showStats) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StatChunk(label: "Min", frequency: stats.min, playAction: {
                        tonePlayer.play(frequency: stats.min, duration: 0.5, amplitudes: toneSettings.harmonicAmplitudes, attack: 0.01, release: 0.05)
                    })
                    StatChunk(label: "Max", frequency: stats.max, playAction: {
                        tonePlayer.play(frequency: stats.max, duration: 0.5, amplitudes: toneSettings.harmonicAmplitudes, attack: 0.01, release: 0.05)
                    })
                    StatChunk(label: "Median", frequency: stats.median, playAction: {
                        tonePlayer.play(frequency: stats.median, duration: 0.5, amplitudes: toneSettings.harmonicAmplitudes, attack: 0.01, release: 0.05)
                    })
                    StatChunk(label: "Avg", frequency: stats.avg, playAction: {
                        tonePlayer.play(frequency: stats.avg, duration: 0.5, amplitudes: toneSettings.harmonicAmplitudes, attack: 0.01, release: 0.05)
                    })
                    SimpleStatChunk(label: "Std Dev", value: stats.stdDev, unit: "Hz")
                    SimpleStatChunk(label: "IQR", value: stats.iqr, unit: "Hz")
                    SimpleStatChunk(label: "RMS", value: stats.rms, unit: "Hz")
                }
                .padding(.top, 4)
            }
            .accentColor(.accentColor) // Use global accent color
            .padding(.top, 4)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.tertiarySystemBackground)))
        .padding(.vertical, 6)
    }
}

// MARK: - Helper Chunks and Sparkline

func noteNameAndCents(for frequency: Double) -> (String, Int) {
    guard frequency > 0 else { return ("–", 0) }
    let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let midi = 69 + 12 * log2(frequency / 440)
    let noteNum = Int(round(midi))
    let noteIndex = (noteNum + 120) % 12 // Ensure positive index
    let noteName = noteNames[noteIndex]
    let noteHz = 440 * pow(2.0, Double(noteNum - 69) / 12)
    let cents = Int(round(1200 * log2(frequency / noteHz)))
    return (noteName, cents)
}

struct StatChunk: View {
    let label: String
    let frequency: Double
    let playAction: (() -> Void)?

    var body: some View {
        let (note, cents) = noteNameAndCents(for: frequency)
        let centsString = cents == 0 ? " (in tune)" : String(format: " (%+d¢)", cents)
        Button(action: { playAction?() }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.2f Hz", frequency))
                        .font(.headline)
                    Text("\(note)\(centsString)")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground)) // Use adaptable color
                            .shadow(radius: 1, y: 1))
        }
        .buttonStyle(.plain) // More subtle button style
    }
}

struct SimpleStatChunk: View {
    let label: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f %@", value, unit))
                .font(.headline)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground)) // Use adaptable color
                        .shadow(radius: 1, y: 1))
    }
}

struct Sparkline: Shape {
    let data: [Double]
    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        let minY = data.min() ?? 0
        let maxY = data.max() ?? 1 // Avoid division by zero if all values are same
        let yRange = (maxY - minY == 0) ? 1 : (maxY - minY)
        let stepX = rect.width / CGFloat(data.count - 1)
        let scaleY = rect.height / CGFloat(yRange)

        var path = Path()
        for (i, value) in data.enumerated() {
            let x = CGFloat(i) * stepX
            let y = rect.height - (CGFloat(value - minY) * scaleY)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

// MARK: - Preview Stubs & Data (assumed for compilation)
// These should match your actual project structure.

// Assuming SessionStore is defined elsewhere and is an ObservableObject
class SessionStore: ObservableObject {
    @Published var sessions: [SessionData] = []
    func deleteSession(id: UUID) { sessions.removeAll { $0.id == id } }
}

struct SessionData: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var duration: Double = 0.0
    var statistics: PitchStatistics = PitchStatistics()
    var values: [Double] = []
    var profileName: String = "Default"
    var chakraTimeline: PitchChakraTimeline? = nil // Optional
}

struct PitchStatistics {
    var min: Double = 0.0
    var max: Double = 0.0
    var avg: Double = 0.0
    var median: Double = 0.0
    var stdDev: Double = 0.0
    var iqr: Double = 0.0
    var rms: Double = 0.0
}

struct PitchChakraTimeline { // Basic stub
    var pitches: [Double] = []
}

// If TonePlayer is not globally available, a stub here:
// class TonePlayer: ObservableObject {
//     func play(frequency: Double, duration: Double, amplitudes: HarmonicAmplitudes, attack: Double, release: Double) {}
//     func play(frequency: Double, duration: Double) {}
//     func stop() {}
// }


struct SavedSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = SessionStore()
        let sampleStats = PitchStatistics(min: 100, max: 200, avg: 150, median: 145, stdDev: 20, iqr: 30, rms: 160)
        let date1 = Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let pitches1: [Double] = (0..<32).map { 220 + 50 * sin(Double($0)/4) + Double.random(in: -5...5) }
        let pitches2: [Double] = (0..<40).map { 330 + 80 * cos(Double($0)/7) + Double.random(in: -8...8) }

        mockStore.sessions.append(SessionData(
            date: date1,
            duration: 300,
            statistics: sampleStats,
            values: pitches1,
            profileName: "User1",
            chakraTimeline: PitchChakraTimeline(pitches: pitches1)
        ))
        mockStore.sessions.append(SessionData(
            date: date2,
            duration: 650,
            statistics: sampleStats,
            values: pitches2,
            profileName: "User2",
            chakraTimeline: PitchChakraTimeline(pitches: pitches2)
        ))

        return SavedSessionsView()
            .environmentObject(mockStore)
            .environmentObject(ToneSettingsManager.shared) // For preview
            .preferredColorScheme(.dark)
    }
}
