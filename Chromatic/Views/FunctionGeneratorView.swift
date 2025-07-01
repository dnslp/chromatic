//
//  FunctionGeneratorView.swift
//  Chromatic
//
//  Created by David Nyman on 7/1/25.
//


import SwiftUI

struct FunctionGeneratorView: View {
    @ObservedObject var engine = FunctionGeneratorEngine()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🔊 4-Channel Function Generator")
                    .font(.title2)
                    .padding(.top)

                ForEach(Array(engine.channels.enumerated()), id: \.1.id) { idx, channel in
                    Section(header: Text("Channel \(idx+1)").font(.headline)) {
                        Picker("Waveform", selection: Binding(
                            get: { channel.waveform },
                            set: { engine.setWaveform($0, for: idx) }
                        )) {
                            ForEach(Waveform.allCases) { wf in
                                Text(wf.rawValue.capitalized).tag(wf)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Picker("Pitch", selection: Binding(
                            get: { channel.selectedPitch?.name ?? (pitchFrequencies.first(where: { $0.name == "A4" })?.name ?? pitchFrequencies.first!.name) },
                            set: { selectedName in
                                if let newPitch = pitchFrequencies.first(where: { $0.name == selectedName }) {
                                    engine.channels[idx].selectedPitch = newPitch
                                    // The frequency will be updated automatically by the Channel's didSet for selectedPitch
                                }
                            }
                        )) {
                            ForEach(pitchFrequencies) { pitch in
                                Text(pitch.name).tag(pitch.name) // Tag with pitch.name (String)
                            }
                        }

                        VStack(alignment: .leading) {
                            Text("Freq: \(Int(channel.frequency)) Hz (\(channel.selectedPitch?.name ?? "N/A"))")
                            Slider(
                                value: Binding(
                                    get: { channel.frequency },
                                    set: { newValue in
                                        engine.setFrequency(newValue, for: idx)
                                        // The logic to update selectedPitch is now in the Channel's didSet for frequency
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
                                    set: { engine.setGain($0, for: idx) }
                                ),
                                in: 0...1
                            )
                        }

                        // Start/Stop controls
                        HStack(spacing: 20) {
                            Button(action: { engine.channels[idx].isPlaying = true }) {
                                Text("Start")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor.opacity(channel.isPlaying ? 0.7 : 0.2))
                                    .cornerRadius(8)
                            }
                            Button(action: { engine.channels[idx].isPlaying = false }) {
                                Text("Stop")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(channel.isPlaying ? 0.2 : 0.7))
                                    .cornerRadius(8)
                            }
                        }
                    }
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
        FunctionGeneratorView()
    }
}
