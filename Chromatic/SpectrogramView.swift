//
//  SpectrogramView.swift
//  Chromatic
//
//  Created by David Nyman on 7/6/25.
//

import SwiftUI
import AudioKit
struct SpectrogramView: View {
    var body: some View {
        SpectrogramFlatView(node: Mixer())
    }
}

#Preview {
    SpectrogramView()
}
