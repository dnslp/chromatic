import SwiftUI
import AVFoundation


import AVFoundation

struct HarmonicAmplitudes {
    var fundamental: Double = 1.0
    var harmonic2: Double = 0.10
    var harmonic3: Double = 0.05
    var formant: Double = 0.05
}

class TonePlayer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isConfigured = false

    init() {
        setupEngine()
    }

    private func setupEngine() {
        guard !isConfigured else { return }
        audioEngine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        try? audioEngine.start()
        isConfigured = true
    }

    func play(frequency: Double, duration: Double = 1.2, amplitudes: HarmonicAmplitudes) {
        stop()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let attackTime: Double = 0.04
        let releaseTime: Double = 0.12

        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate

            let fund = amplitudes.fundamental * sin(2 * .pi * frequency * t)
            let harm2 = amplitudes.harmonic2 * sin(2 * .pi * frequency * 2 * t)
            let harm3 = amplitudes.harmonic3 * sin(2 * .pi * frequency * 3 * t)
            let formant = amplitudes.formant * sin(2 * .pi * 1200 * t)

            var sample = fund + harm2 + harm3 

            var env: Double = 1.0
            if t < attackTime {
                env = t / attackTime
            } else if t > duration - releaseTime {
                env = max(0, (duration - t) / releaseTime)
            }
            sample *= env
            buffer.floatChannelData![0][i] = Float(sample * 0.27)
        }

        player.scheduleBuffer(buffer, at: nil, options: []) { }
        if !player.isPlaying {
            player.play()
        }
    }

    func stop() {
        if player.isPlaying {
            player.stop()
        }
    }
}



struct SavedSessionsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: SessionData?
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationView {
            List {
                if sessionStore.sessions.isEmpty {
                    Text("No saved sessions yet.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(sessionStore.sessions) { session in
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
                    .onDelete(perform: deleteSession)
                }
            }
            .navigationTitle("Saved Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sessionStore.sessions.isEmpty {
                        EditButton()
                    }
                }
            }
            .alert("Delete Session?", isPresented: $showingDeleteAlert, presenting: sessionToDelete) { sessionDetail in
                Button("Delete", role: .destructive) {
                    sessionStore.deleteSession(id: sessionDetail.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: { sessionDetail in
                Text("Are you sure you want to delete the session from \(formattedDate(sessionDetail.date))? This action cannot be undone.")
            }
        }
    }

    private func deleteSession(at offsets: IndexSet) {
        sessionStore.deleteSession(at: offsets)
    }
}

// MARK: - Session Row with Sparkline


// Utility to convert frequency to note + cents
func noteNameAndCents(for frequency: Double) -> (String, Int) {
    guard frequency > 0 else { return ("–", 0) }
    let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let midi = 69 + 12 * log2(frequency / 440)
    let noteNum = Int(round(midi))
    let noteIndex = (noteNum + 120) % 12
    let noteName = noteNames[noteIndex]
    let noteHz = 440 * pow(2.0, Double(noteNum - 69) / 12)
    let cents = Int(round(1200 * log2(frequency / noteHz)))
    return (noteName, cents)
}

// "Chunk"/Card for a statistic
struct StatChunk: View {
    let label: String
    let frequency: Double
    let playAction: (() -> Void)?

    var body: some View {
        let (note, cents) = noteNameAndCents(for: frequency)
        let centsString = cents == 0 ? " (in tune)" :
            String(format: " (%+d¢)", cents)
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
                            .fill(Color(.secondarySystemBackground))
                            .shadow(radius: 1, y: 1))
        }
        .buttonStyle(.plain)
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
                        .fill(Color(.secondarySystemBackground))
                        .shadow(radius: 1, y: 1))
    }
}


private struct SessionRowView: View {
    let session: SessionData
    @State private var tonePlayer = TonePlayer()

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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date: \(dateString)").bold()
                    Text("Duration: \(durationString)").bold()
                }
                Spacer()
                if !session.values.isEmpty {
                    Sparkline(data: session.values)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemBackground))
                        )
                        .padding(.leading, 8)
                }
            }

            Divider().padding(.vertical, 2)

            // Stats in a grid of data chunks
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatChunk(label: "Min", frequency: stats.min, playAction: nil)
                StatChunk(label: "Max", frequency: stats.max, playAction: nil)
                StatChunk(label: "Median", frequency: stats.median, playAction: {
                    tonePlayer.play(frequency: stats.median, amplitudes: HarmonicAmplitudes())
                })
                StatChunk(label: "Avg", frequency: stats.avg, playAction: {
                    tonePlayer.play(frequency: stats.avg, amplitudes: HarmonicAmplitudes())
                })
                SimpleStatChunk(label: "Std Dev", value: stats.stdDev, unit: "Hz")
                SimpleStatChunk(label: "IQR", value: stats.iqr, unit: "Hz")
                SimpleStatChunk(label: "RMS", value: stats.rms, unit: "Hz")
            }

        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.tertiarySystemBackground)))
        .padding(.vertical, 6)
    }
}

// ---- Sparkline Shape ----
struct Sparkline: Shape {
    let data: [Double]
    
    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        let minY = data.min() ?? 0
        let maxY = data.max() ?? 1
        let yRange = maxY - minY == 0 ? 1 : maxY - minY

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


// MARK: - Previews

struct SavedSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = SessionStore()
        let sampleStats = PitchStatistics(min: 100, max: 200, avg: 150, median: 145, stdDev: 20, iqr: 30, rms: 160)
        mockStore.addSession(duration: 300, statistics: sampleStats, values: [120, 130, 140, 155, 170, 155, 145, 150, 148, 147, 149, 151, 153, 157, 154, 150])
        mockStore.addSession(duration: 650, statistics: sampleStats, values: [135, 137, 139, 142, 148, 151, 153, 154, 155, 153, 151, 150, 148, 147, 146, 144])
        
        return SavedSessionsView()
            .environmentObject(mockStore)
            .preferredColorScheme(.dark)
            .previewDisplayName("Saved Sessions w/ Sparklines")
    }
}
