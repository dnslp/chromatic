//
//  FunctionGeneratorView.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//


import SwiftUI

struct FunctionGeneratorView: View {
    @ObservedObject var engine: FunctionGeneratorEngine

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

                Spacer(minLength: 50)
            }
            .padding(.horizontal)
        }
    }
}

struct FunctionGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        FunctionGeneratorView(engine: FunctionGeneratorEngine(engine: AVAudioEngine()))
    }
}
