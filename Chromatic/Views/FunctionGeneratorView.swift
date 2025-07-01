//
//  FunctionGeneratorView.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//


import SwiftUI
import MicrophonePitchDetector // Import to use MicrophonePitchDetector

struct FunctionGeneratorView: View {
    @StateObject var engine: FunctionGeneratorEngine // Accept engine as a parameter
    @ObservedObject var pitchDetector: MicrophonePitchDetector // Add pitchDetector

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🔊 4-Channel Function Generator")
                    .font(.title2)
                    .padding(.top)

                ForEach(Array(engine.channels.enumerated()), id: \.1.id) { idx, currentChannel in
                    ChannelView(channel: currentChannel, channelIndex: idx, engine: engine)
                    Divider()
                }

                // Add MiniTunerView here, within the VStack but after the channels
                MiniTunerView(pitchDetector: pitchDetector)
                    .padding(.top, 10) // Add some space above it

                Spacer(minLength: 50) // Existing spacer
            }
            .padding(.horizontal)
        }
        // The .task for activating pitchDetector is in MiniTunerView itself
    }
}

struct FunctionGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide both dependencies for the preview
        FunctionGeneratorView(
            engine: FunctionGeneratorEngine(),
            pitchDetector: MicrophonePitchDetector()
        )
    }
}
