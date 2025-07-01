//
//  MiniTunerView.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//

import SwiftUI

struct MiniTunerView: View {
    let tunerData: TunerData
    @Binding var modifierPreference: ModifierPreference
    @Binding var selectedTransposition: Int

    /// Uniform scale for the mini version
    private let scale: CGFloat = 0.4
    /// Base height after scaling to lock in place
    private let baseHeight: CGFloat = 200

    private var match: ScaleNote.Match {
        tunerData.closestNote.inTransposition(ScaleNote.allCases[selectedTransposition])
    }

    var body: some View {
        VStack(alignment: .noteCenter, spacing: 4) {
            MatchedNoteView(
                match: match,
                modifierPreference: modifierPreference
            )
            NoteTicks(
                tunerData: tunerData,
                showFrequencyText: false
            )
        }
        .scaleEffect(scale, anchor: .center)
        // lock the height so it never shifts
        .frame(height: baseHeight)
        .clipped()
    }
}

struct MiniTunerView_Previews: PreviewProvider {
    static var previews: some View {
        MiniTunerView(
            tunerData: TunerData(pitch: 440, amplitude: 0.5),
            modifierPreference: .constant(.preferSharps),
            selectedTransposition: .constant(0)
        )
        .previewLayout(.sizeThatFits)
    }
}
