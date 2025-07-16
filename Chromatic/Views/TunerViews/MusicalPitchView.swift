//
//  MusicalPitchView.swift
//  Chromatic
//
//  Created by David Nyman on 7/16/25.
//

import SwiftUI
import AVFoundation

// MARK: - TunerView

struct MusicalPitchView: View {
    @Binding var tunerData: TunerData
    @State var modifierPreference: ModifierPreference
    @State var selectedTransposition: Int
    
    @State private var showingToneSettings = false
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var userF0: Double = 77.78
    @State private var micMuted = false
    @State private var sessionStats: SessionStatistics?
    @State private var showStatsModal = false
    @State private var showingProfileSelector = false
    @State private var countdown: Int? = nil
    let countdownSeconds = 3
    
    // Timer State
    @State private var recordingStartedAt: Date?
    private var elapsed: TimeInterval {
        guard let start = recordingStartedAt else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }
    @AppStorage("HidesTranspositionMenu") private var hidesTranspositionMenu = false
    
    // Layout constants
    private let nonWatchHeight: CGFloat = 560
    private let menuHeight: CGFloat = 44
    private let contentSpacing: CGFloat = 8
    private let noteTicksHeight: CGFloat = 100
    private let amplitudeBarHeight: CGFloat = 32
    private let maxCentDistance: Double = 50
    
    
    
    
    // MARK: - Main Body
    var body: some View {
        HStack(spacing: 0) {
            
            // ────────── MAIN CONTENT ──────────
            VStack(spacing: 0) {
                // ───── NOTE DISPLAY ─────
                VStack(spacing: contentSpacing) {
                    MatchedNoteView(match: match, modifierPreference: modifierPreference)
                        .padding(.top, 0)
                    MatchedNoteFrequency(frequency: tunerData.closestNote.frequency)
                        .padding(.bottom, 0)
                    NoteTicks(tunerData: tunerData, showFrequencyText: true)
                        .frame(height: 100)
                        .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.top, 0)

                
            }
        }
    }
}
// MARK: - TunerView Preview

struct MusicalPitchView_Previews: PreviewProvider {
    static var previews: some View {
        MusicalPitchView(
            tunerData: .constant(TunerData(pitch: 428, amplitude: 0.5)),
            modifierPreference: .preferSharps,
            selectedTransposition: 0
        )
        .environmentObject(UserProfileManager())
        .previewLayout(.device)
        .padding()
    }
}
