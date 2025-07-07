import SwiftUI
import AVFoundation

// MARK: - Main View

struct SavedSessionsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: SessionData?
    @State private var expandedDays: Set<Date> = []
    
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
            .navigationTitle("Saved Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sessionStore.sessions.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Session Row with Sparkline

private struct SessionRowView: View {
    let session: SessionData
    @StateObject private var tonePlayer = TonePlayer()
    @State private var showStats = false  // <--- Move here!
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
            
            DisclosureGroup("Show Stats", isExpanded: $showStats) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StatChunk(label: "Min", frequency: stats.min, playAction: { tonePlayer.play(frequency: stats.min) })
                    StatChunk(label: "Max", frequency: stats.max, playAction: { tonePlayer.play(frequency: stats.max) })
                    StatChunk(label: "Median", frequency: stats.median, playAction: { tonePlayer.play(frequency: stats.median) })
                    StatChunk(label: "Avg", frequency: stats.avg, playAction: { tonePlayer.play(frequency: stats.avg) })
                    SimpleStatChunk(label: "Std Dev", value: stats.stdDev, unit: "Hz")
                    SimpleStatChunk(label: "IQR", value: stats.iqr, unit: "Hz")
                    SimpleStatChunk(label: "RMS", value: stats.rms, unit: "Hz")
                }
                .padding(.top, 4)
            }
            .accentColor(.accentColor)
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
    let noteIndex = (noteNum + 120) % 12
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

// MARK: - Preview

struct SavedSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = SessionStore()
        let sampleStats = PitchStatistics(min: 100, max: 200, avg: 150, median: 145, stdDev: 20, iqr: 30, rms: 160)
        // Add sessions manually
        let date1 = Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        mockStore.sessions.append(SessionData(id: UUID(), date: date1, duration: 300, statistics: sampleStats, values: [120, 130, 140, 155]))
        mockStore.sessions.append(SessionData(id: UUID(), date: date2, duration: 650, statistics: sampleStats, values: [135, 137, 139, 142]))
        // ...add more if desired
        return SavedSessionsView()
            .environmentObject(mockStore)
            .preferredColorScheme(.dark)
    }
}
