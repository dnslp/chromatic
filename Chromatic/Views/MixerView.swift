//
//  MixerView.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//


// MixerView.swift
// SwiftUI interface for selecting files and mixing

import SwiftUI

struct MixerView: View {
    @ObservedObject var mixer = MixerEngine()
    @State private var filePickerIndex: Int? = nil

    var body: some View {
        VStack {
            List {
                ForEach(Array(mixer.tracks.enumerated()), id: \.offset) { index, track in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(track.name)
                            Spacer()
                            Button("Load") {
                                filePickerIndex = index
                            }
                        }
                        Slider(value: Binding(
                            get: { mixer.tracks[index].volume },
                            set: { mixer.setVolume($0, for: index) }
                        ), in: 0...1) {
                            Text("Volume")
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .frame(height: 300)

            HStack(spacing: 40) {
                Button("Play All") { mixer.playAll() }
                Button("Pause All") { mixer.pauseAll() }
                Button("Stop All") { mixer.stopAll() }
            }
            .padding()
        }
        .fileImporter(
            isPresented: Binding(
                get: { filePickerIndex != nil },
                set: { if !$0 { filePickerIndex = nil } }
            ),
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            do {
                if let url = try result.get().first,
                   let idx = filePickerIndex {
                    mixer.loadFile(url, for: idx)
                }
            } catch {
                print("❌ File import error: \(error)")
            }
            filePickerIndex = nil
        }
    }
}

struct MixerView_Previews: PreviewProvider {
    static var previews: some View {
        MixerView()
    }
}
