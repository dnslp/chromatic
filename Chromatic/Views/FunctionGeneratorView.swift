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
                Text("🔊Function Generator")
                    .font(.title2)
                    .padding(.top)

                ChannelView(channel: engine.channels[0],
                engine: engine)

                Spacer(minLength: 50)
            }
            .padding(.horizontal)
        }
    }
}

struct FunctionGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        FunctionGeneratorView()
    }
}
