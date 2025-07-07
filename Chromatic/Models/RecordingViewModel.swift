import SwiftUI
import Combine // Required for ObservableObject and Timer

// Assuming TunerData and SessionStatistics are defined elsewhere
// and accessible here. If not, their definitions or relevant parts
// would need to be included or imported.

class RecordingViewModel: ObservableObject {
    private var tunerData: TunerData // Assuming TunerData is a class or struct that handles the core recording logic.
                                     // If it's a struct and its properties are modified, this needs to be a @Binding or handled appropriately.

    @Published var countdown: Int? = nil
    @Published var isRecording: Bool = false // Mirrored from tunerData
    @Published var sessionStats: SessionStatistics? = nil
    @Published var showStatsModal: Bool = false

    private var recordingStartedAt: Date?
    let countdownSeconds: Int = 7
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(tunerData: TunerData) {
        self.tunerData = tunerData

        // If TunerData has a publisher for isRecording or similar, subscribe to it.
        // For simplicity, we'll assume direct access or a simple notification mechanism for now.
        // This might need to be adjusted based on how TunerData signals changes.
        // For example, if TunerData is an ObservableObject:
        // tunerData.$isRecording.assign(to: &$isRecording)
        // Or, we might need a more manual update if TunerData uses delegates or notifications.
        // For now, we'll rely on TunerView to update this VM or pass a binding.
        // A more robust way would be to have TunerData publish its state.
        self.isRecording = tunerData.isRecording
    }

    func startOrStopRecording() {
        if tunerData.isRecording {
            stopRecording()
        } else {
            initiateCountdownAndStartRecording()
        }
    }

    private func initiateCountdownAndStartRecording() {
        countdown = countdownSeconds
        countdownTimer?.invalidate() // Invalidate any existing timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if let currentCountdown = self.countdown, currentCountdown > 1 {
                self.countdown = currentCountdown - 1
            } else {
                timer.invalidate()
                self.countdown = nil
                self.actuallyStartRecording()
            }
        }
    }

    private func actuallyStartRecording() {
        tunerData.startRecording() // This should ideally update tunerData.isRecording
        self.isRecording = true // Reflect the change
        sessionStats = nil
        recordingStartedAt = Date()
    }

    func stopRecording() {
        tunerData.stopRecording() // This should ideally update tunerData.isRecording
        self.isRecording = false // Reflect the change
        let sessionDuration = Date().timeIntervalSince(recordingStartedAt ?? Date())
        sessionStats = tunerData.calculateStatisticsExtended(duration: max(0, sessionDuration))
        showStatsModal = true
        recordingStartedAt = nil
        countdownTimer?.invalidate()
        countdown = nil
    }

    func clearRecordingData() {
        tunerData.clearRecording()
        if tunerData.isRecording { // If it was recording, stop it
            stopRecording() // This also clears stats and recordingStartedAt
        } else {
            // If not recording, just clear the stats and date
            sessionStats = nil
            recordingStartedAt = nil
        }
        self.isRecording = tunerData.isRecording // Ensure isRecording state is accurate
        showStatsModal = false // Hide modal if it was shown
    }

    // Call this method if TunerData's isRecording state can change externally
    // and RecordingViewModel needs to be kept in sync.
    func syncRecordingState(isRecording: Bool) {
        self.isRecording = isRecording
        if !isRecording && self.countdown != nil {
            // If recording was stopped externally during a countdown, cancel the countdown.
            countdownTimer?.invalidate()
            countdown = nil
        }
    }
}
