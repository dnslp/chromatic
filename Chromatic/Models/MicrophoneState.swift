//
//  MicrophoneState.swift
//  Chromatic
//
//  Created by Jules on 10/24/2023.
//

import Foundation

/// Represents the possible states for microphone input.
enum MicrophoneState: String, CaseIterable, Identifiable {
    case on = "On"
    case muted = "Muted"
    case pushToTalk = "Push to Talk"

    var id: String { self.rawValue }
}
