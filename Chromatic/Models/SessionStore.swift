import Foundation

struct SessionData: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let statistics: PitchStatistics // Ensure PitchStatistics is Codable
    let values: [Double]
    let profileName: String

    // Explicit initializer to include profileName and match Codable requirements
    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, statistics: PitchStatistics, values: [Double], profileName: String) {
        self.id = id
        self.date = date
        self.duration = duration
        self.statistics = statistics
        self.values = values
        self.profileName = profileName
    }

    // Coding keys to handle the new property
    enum CodingKeys: String, CodingKey {
        case id, date, duration, statistics, values, profileName
    }

    // Custom decoder to handle old data without profileName
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        statistics = try container.decode(PitchStatistics.self, forKey: .statistics)
        values = try container.decode([Double].self, forKey: .values)
        profileName = try container.decodeIfPresent(String.self, forKey: .profileName) ?? "Guest" // Default if missing
    }

    // Custom encoder to include profileName
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(duration, forKey: .duration)
        try container.encode(statistics, forKey: .statistics)
        try container.encode(values, forKey: .values)
        try container.encode(profileName, forKey: .profileName)
    }
}

// Removed duplicate PitchStatistics struct definition

class SessionStore: ObservableObject {
    @Published var sessions: [SessionData] = []
    private let sessionsKey = "savedSessions"

    init() {
        loadSessions()
    }

    func addSession(duration: TimeInterval, statistics: PitchStatistics, values: [Double], profileName: String) {
        // Use the comprehensive initializer for SessionData
        let newSession = SessionData(duration: duration, statistics: statistics, values: values, profileName: profileName)
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
