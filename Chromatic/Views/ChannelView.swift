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

            // VU Meter for the channel
            VStack(alignment: .leading, spacing: 2) {
                Text("Output Level")
                    .font(.caption)
                ProgressView(value: normalizeFunctionGeneratorPower(channel.averagePower), total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .frame(height: 8)
                Text(String(format: "%.1f dB", channel.averagePower))
                    .font(.caption2) // Smaller font for dB value
            }
            .padding(.top, 5) // Add some space above the VU meter

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

    // Helper to normalize dBFS to 0-1 range for ProgressView
    // Similar to PlayerView, but specific for Function Generator if needed
    private func normalizeFunctionGeneratorPower(_ power: Float) -> Double {
        let minDb: Float = -60.0 // Typical dynamic range visualization floor
        let maxDb: Float = 0.0   // Peak

        let clampedPower = max(minDb, min(power, maxDb))
        let normalized = (clampedPower - minDb) / (maxDb - minDb)
        return Double(normalized)
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock FunctionGeneratorEngine and Channel for preview
        let mockEngine = FunctionGeneratorEngine(channelsCount: 1)
        let mockChannel: Channel

        if !mockEngine.channels.isEmpty {
            mockChannel = mockEngine.channels[0]
            mockChannel.gain = 0.6
            mockChannel.averagePower = -15.5 // Example power
            mockChannel.isPlaying = true
        } else {
            // Fallback if engine somehow fails to create channels for preview
            // This shouldn't happen with the current FunctionGeneratorEngine implementation
            let dummyFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            mockChannel = Channel(format: dummyFormat)
            mockChannel.gain = 0.0
            mockChannel.averagePower = -160.0
        }

        return Form { // Using Form to mimic typical layout context for Sections
            ChannelView(channel: mockChannel, channelIndex: 0, engine: mockEngine)
        }
        .previewLayout(.sizeThatFits)
    }
}
