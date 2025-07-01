//
//  FunctionGeneratorView.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//


import SwiftUI

struct FunctionGeneratorView: View {
    @StateObject var engine = FunctionGeneratorEngine() // Changed to @StateObject

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("🔊 4-Channel Function Generator")
                        .font(.title2)
                    Spacer()
                    Image(systemName: "power.circle.fill") // Example Icon
                        .foregroundColor(engine.isAnyChannelPlaying ? .green : .gray)
                        .font(.title2) // Match title font size
                }
                .padding(.top)
                .padding(.horizontal) // Ensure icon also gets horizontal padding if title did

                ForEach(Array(engine.channels.enumerated()), id: \.1.id) { idx, currentChannel in
                    ChannelView(channel: currentChannel, channelIndex: idx, engine: engine)
                    Divider()
                }

                Spacer(minLength: 50)
            }
            .padding(.horizontal)
        }
    }
}

struct FunctionGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with no channels playing
        let engineNotPlaying = FunctionGeneratorEngine(channelsCount: 2)

        // Preview with one channel playing
        let enginePlaying = FunctionGeneratorEngine(channelsCount: 2)
        if !enginePlaying.channels.isEmpty {
            enginePlaying.channels[0].isPlaying = true
            // The engine's isAnyChannelPlaying should update automatically due to Combine publisher
        }

        return Group {
            FunctionGeneratorView(engine: engineNotPlaying)
                .previewDisplayName("All Channels Off")

            FunctionGeneratorView(engine: enginePlaying)
                .previewDisplayName("One Channel On")
        }
    }
}
