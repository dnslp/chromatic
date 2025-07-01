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
                            get: { channel.selectedPitch }, // Bind directly to the optional
                            set: { selectedPitchFromPicker in
                                // User selection from Picker will always be a non-nil Pitch.
                                // Binding is to Pitch? so type is Pitch?, but practically it's Pitch here.
                                if let definitePitch = selectedPitchFromPicker {
                                    engine.channels[idx].selectedPitch = definitePitch
                                    engine.setFrequency(definitePitch.frequency, for: idx)
                                }
                            }
                        )) {
                            ForEach(pitchFrequencies) { pitch in
                                Text(pitch.name).tag(pitch as Pitch?) // Tag as Pitch? to match selection type
                            }
                        }

                        VStack(alignment: .leading) {
                            Text("Freq: \(Int(channel.frequency)) Hz (\(channel.selectedPitch?.name ?? "N/A"))")
                            Slider(
                                value: Binding(
                                    get: { channel.frequency },
                                    set: { newFrequencyValue in
                                        engine.setFrequency(newFrequencyValue, for: idx)

                                        // Find the closest pitch to the newFrequencyValue.
                                        var closestPitchCandidate: Pitch? = nil
                                        var minDifference = Double.infinity

                                        for p in pitchFrequencies {
                                            let diff = abs(p.frequency - newFrequencyValue)
                                            if diff < minDifference {
                                                minDifference = diff
                                                closestPitchCandidate = p
                                            }
                                        }

                                        // If a closest pitch is found and it's within tolerance, update selectedPitch.
                                        // Otherwise, set selectedPitch to nil.
                                        let tolerance = 0.5 // Hz (slider steps by 1 Hz)
                                        if let matched = closestPitchCandidate, minDifference < tolerance {
                                            if engine.channels[idx].selectedPitch?.id != matched.id {
                                                engine.channels[idx].selectedPitch = matched
                                            }
                                        } else {
                                            if engine.channels[idx].selectedPitch != nil {
                                                engine.channels[idx].selectedPitch = nil
                                            }
                                        }
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
