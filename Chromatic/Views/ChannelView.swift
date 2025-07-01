//
//  ChannelView.swift
//  Chromatic
//
//  Created by Jules on 10/26/23.
//

import SwiftUI

struct ChannelView: View {
    @ObservedObject var channel: Channel
    var channelIndex: Int // Renamed from idx for clarity if preferred, or keep as idx
    @ObservedObject var engine: FunctionGeneratorEngine

    // Default pitch name logic will be moved to Channel model later,
    // for now, keeping it here to match original view before further refactoring.
    private var currentDisplayPitchName: String {
        channel.selectedPitch?.name ?? (pitchFrequencies.first(where: { $0.name == "A4" })?.name ?? pitchFrequencies.first!.name)
    }

    var body: some View {
        Section(header: Text("Channel \(channelIndex + 1)").font(.headline)) {
            Picker("Waveform", selection: Binding(
                get: { channel.waveform },
                set: { engine.setWaveform($0, for: channelIndex) }
            )) {
                ForEach(Waveform.allCases) { wf in
                    Text(wf.rawValue.capitalized).tag(wf)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Pitch", selection: Binding(
                get: { currentDisplayPitchName }, // Uses the computed property
                set: { selectedName in
                    if let newPitch = pitchFrequencies.first(where: { $0.name == selectedName }) {
                        engine.channels[channelIndex].selectedPitch = newPitch
                    }
                }
            )) {
                ForEach(pitchFrequencies) { pitch in
                    Text(pitch.name).tag(pitch.name)
                }
            }

            VStack(alignment: .leading) {
                // Updated Text label to display pitch and cents deviation
                if let selectedPitch = channel.selectedPitch {
                    // Snapped to a pitch or very close (within 0.5 Hz tolerance)
                    Text("\(selectedPitch.name) (\(Int(channel.frequency)) Hz)")
                } else if let pitchInfo = channel.closestPitchAndDeviation {
                    let sign = pitchInfo.deviationInCents >= 0 ? "+" : ""
                    let formattedCents = String(format: "%.1f", pitchInfo.deviationInCents)
                    Text("\(pitchInfo.closestPitch.name) \(sign)\(formattedCents) cents (\(Int(channel.frequency)) Hz)")
                } else {
                    // Fallback if no pitch info can be determined (e.g., pitchFrequencies is empty)
                    Text("Freq: \(Int(channel.frequency)) Hz (N/A)")
                }
                Slider(
                    value: Binding(
                        get: { channel.frequency },
                        set: { newValue in
                            engine.setFrequency(newValue, for: channelIndex)
                        }
                    ),
                    in: 20...5000,
                    step: 1
                )
            }

            VStack(alignment: .leading) {
                Text("Vol: \(String(format: "%.2f", channel.gain))")
                Slider(
                    value: Binding(
                        get: { channel.gain },
                        set: { engine.setGain($0, for: channelIndex) }
                    ),
                    in: 0...1
                )
            }

            // Start/Stop controls
            HStack(spacing: 20) {
                Button(action: { engine.channels[channelIndex].isPlaying = true }) {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(channel.isPlaying ? 0.7 : 0.2))
                        .cornerRadius(8)
                }
                Button(action: { engine.channels[channelIndex].isPlaying = false }) {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(channel.isPlaying ? 0.2 : 0.7))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// Preview can be added later if needed, might require a mock Channel and Engine.
// struct ChannelView_Previews: PreviewProvider {
//     static var previews: some View {
//         // Need to create mock/sample Channel and FunctionGeneratorEngine instances
//         // For example:
//         // let engine = FunctionGeneratorEngine(channelsCount: 1)
//         // if !engine.channels.isEmpty {
//         //     ChannelView(channel: engine.channels[0], channelIndex: 0, engine: engine)
//         // } else {
//         //     Text("No channel available for preview")
//         // }
//     }
// }
