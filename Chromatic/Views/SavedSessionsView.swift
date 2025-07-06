import SwiftUI

struct SavedSessionsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: SessionData?

    var body: some View {
        NavigationView {
            List {
                if sessionStore.sessions.isEmpty {
                    Text("No saved sessions yet.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(sessionStore.sessions) { session in
                        VStack(alignment: .leading) {
                            Text("Date: \(session.date, style: .medium)")
                            Text("Duration: \(formatTime(session.duration))")
                            // Add more details if needed, e.g., average pitch
                            Text(String(format: "Avg Pitch: %.2f Hz", session.statistics.avg))
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                self.sessionToDelete = session
                                self.showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteSession) // Alternative direct delete if preferred
                }
            }
            .navigationTitle("Saved Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sessionStore.sessions.isEmpty {
                        EditButton() // Allows enabling swipe-to-delete for multiple items
                    }
                }
            }
            .alert("Delete Session?", isPresented: $showingDeleteAlert, presenting: sessionToDelete) { sessionDetail in
                Button("Delete", role: .destructive) {
                    if let sessionID = sessionDetail.id { // Assuming SessionData has an id
                        sessionStore.deleteSession(id: sessionID)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { sessionDetail in
                Text("Are you sure you want to delete the session from \(sessionDetail.date, style: .medium)? This action cannot be undone.")
            }
        }
    }

    private func deleteSession(at offsets: IndexSet) {
        // This is an alternative way to handle deletion directly from .onDelete
        // If you prefer the alert, you can remove this or choose one method.
        sessionStore.deleteSession(at: offsets)
    }

    // Helper to format time as MM:SS or H:MM:SS (copied from StatsModalView for now)
    // Consider moving this to a shared utility file if used in multiple places.
    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct SavedSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock SessionStore with some sample data for previewing
        let mockStore = SessionStore()
        // Add sample sessions to mockStore for preview
        let sampleStats = PitchStatistics(min: 100, max: 200, avg: 150, median: 145, stdDev: 20, iqr: 30, rms: 160)
        mockStore.addSession(duration: 300, statistics: sampleStats, values: [140, 150, 160])
        mockStore.addSession(duration: 650, statistics: sampleStats, values: [130, 145, 155])

        return SavedSessionsView()
            .environmentObject(mockStore)
    }
}
