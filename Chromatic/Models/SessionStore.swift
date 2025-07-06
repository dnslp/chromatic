import Foundation

struct SessionData: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let statistics: PitchStatistics
    let values: [Double]
}

struct PitchStatistics: Codable {
    let min: Double
    let max: Double
    let avg: Double
    let median: Double
    let stdDev: Double
    let iqr: Double
    let rms: Double

    // Assuming PitchStatistics has an initializer like this
    // If not, we might need to adjust how it's created or stored
    init(min: Double, max: Double, avg: Double, median: Double, stdDev: Double, iqr: Double, rms: Double) {
        self.min = min
        self.max = max
        self.avg = avg
        self.median = median
        self.stdDev = stdDev
        self.iqr = iqr
        self.rms = rms
    }
}

class SessionStore: ObservableObject {
    @Published var sessions: [SessionData] = []
    private let sessionsKey = "savedSessions"

    init() {
        loadSessions()
    }

    func addSession(duration: TimeInterval, statistics: PitchStatistics, values: [Double]) {
        let newSession = SessionData(id: UUID(), date: Date(), duration: duration, statistics: statistics, values: values)
        sessions.append(newSession)
        saveSessions()
    }

    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        saveSessions()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }

    private func loadSessions() {
        if let savedSessions = UserDefaults.standard.data(forKey: sessionsKey) {
            if let decodedSessions = try? JSONDecoder().decode([SessionData].self, from: savedSessions) {
                sessions = decodedSessions
                return
            }
        }
        sessions = []
    }
}
