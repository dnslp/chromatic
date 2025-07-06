//
//  SpectogramView.swift
//  Chromatic
//
//  Created by David Nyman on 7/6/25.
//

import SwiftUI
import AudioKit
import MicrophonePitchDetector

struct SpectogramView: View {
    @ObservedObject var pitchDetector: MicrophonePitchDetector

    var body: some View {
        SpectrogramFlatView(node: pitchDetector.inputMixer)
    }
}

#Preview {
    SpectogramView(pitchDetector: MicrophonePitchDetector())
}
