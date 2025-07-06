import SwiftUI

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

private struct SessionRowView: View {
    let session: SessionData

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

    // Format helpers for statistics
    var stats: PitchStatistics { session.statistics }
    var minPitch: String { String(format: "%.2f Hz", stats.min) }
    var maxPitch: String { String(format: "%.2f Hz", stats.max) }
    var avgPitch: String { String(format: "%.2f Hz", stats.avg) }
    var medianPitch: String { String(format: "%.2f Hz", stats.median) }
    var stdDevPitch: String { String(format: "%.2f Hz", stats.stdDev) }
    var iqrPitch: String { String(format: "%.2f Hz", stats.iqr) }
    var rmsPitch: String { String(format: "%.2f Hz", stats.rms) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Date: \(dateString)").bold()
            Text("Duration: \(durationString)").bold()
            Divider().padding(.vertical, 2)
            Group {
                Text("Min Pitch: \(minPitch)")
                Text("Max Pitch: \(maxPitch)")
                Text("Avg Pitch: \(avgPitch)")
                Text("Median Pitch: \(medianPitch)")
                Text("Std Dev: \(stdDevPitch)")
                Text("IQR: \(iqrPitch)")
                Text("RMS: \(rmsPitch)")
            }
            .font(.system(size: 14))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// --- Previews ---

struct SavedSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = SessionStore()
        let sampleStats = PitchStatistics(min: 100, max: 200, avg: 150, median: 145, stdDev: 20, iqr: 30, rms: 160)
        mockStore.addSession(duration: 300, statistics: sampleStats, values: [140, 150, 160])
        mockStore.addSession(duration: 650, statistics: sampleStats, values: [130, 145, 155])
        
        return SavedSessionsView()
            .environmentObject(mockStore)
    }
}
