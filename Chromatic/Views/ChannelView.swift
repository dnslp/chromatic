import SwiftUI

struct ChannelView: View {
    @ObservedObject var channel: Channel
    @ObservedObject var engine: FunctionGeneratorEngine

    // Use local state for sliders to avoid spamming the audio engine
    @State private var localFrequency: Double = 440
    @State private var localGain: Float = 0.5

    // Make sure UI always starts with the channel’s values
    private func syncFromChannel() {
        localFrequency = channel.frequency
        localGain = channel.gain
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Channel \(channel.id.uuidString.prefix(4))").font(.headline)

            // --- Waveform Picker ---
            Picker("Waveform", selection: Binding(
                get: { channel.waveform },
                set: { newValue in
                    if channel.waveform != newValue {
                        channel.waveform = newValue
                        // Update engine only if changed
                        if let idx = engine.channels.firstIndex(where: { $0.id == channel.id }) {
                            engine.setWaveform(newValue, for: idx)
                        }
                    }
                }
            )) {
                ForEach(Waveform.allCases) { wf in
                    Text(wf.rawValue.capitalized).tag(wf)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // --- Pitch Picker ---
            Picker("Pitch", selection: Binding(
                get: { channel.currentDisplayPitchName },
                set: { selectedName in
                    if let newPitch = pitchFrequencies.first(where: { $0.name == selectedName }) {
                        if channel.selectedPitch?.name != newPitch.name {
                            channel.selectedPitch = newPitch
                            // frequency will update via didSet, so just update local slider
                            localFrequency = newPitch.frequency
                        }
                    }
                }
            )) {
                ForEach(pitchFrequencies, id: \.name) { pitch in
                    Text(pitch.name).tag(pitch.name)
                }
            }

            // --- Frequency Slider ---
            VStack(alignment: .leading) {
                Text("Freq: \(Int(localFrequency)) Hz")
                Slider(value: $localFrequency, in: 20...5000, step: 1)
                    .onChange(of: localFrequency) { newValue in
                        // Only set if changed enough (avoids audio thread overload)
                        if abs(channel.frequency - newValue) > 0.2 {
                            channel.frequency = newValue
                            if let idx = engine.channels.firstIndex(where: { $0.id == channel.id }) {
                                engine.setFrequency(newValue, for: idx)
                            }
                        }
                    }
            }
            .onChange(of: channel.frequency) { newFreq in
                // If channel's freq is updated externally, reflect in UI
                if abs(localFrequency - newFreq) > 0.2 {
                    localFrequency = newFreq
                }
            }

            // --- Gain Slider ---
            VStack(alignment: .leading) {
                Text("Vol: \(String(format: "%.2f", localGain))")
                Slider(value: $localGain, in: 0...1)
                    .onChange(of: localGain) { newValue in
                        if abs(channel.gain - newValue) > 0.01 {
                            channel.gain = newValue
                            if let idx = engine.channels.firstIndex(where: { $0.id == channel.id }) {
                                engine.setGain(newValue, for: idx)
                            }
                        }
                    }
            }
            .onChange(of: channel.gain) { newGain in
                if abs(localGain - newGain) > 0.01 {
                    localGain = newGain
                }
            }

            // --- Play Controls ---
            HStack(spacing: 20) {
                Button(action: {
                    channel.isPlaying = true
                    // No need to call engine, audio runs based on channel.isPlaying (see sourceNode closure)
                }) {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(channel.isPlaying ? 0.7 : 0.2))
                        .cornerRadius(8)
                }
                Button(action: {
                    channel.isPlaying = false
                }) {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(channel.isPlaying ? 0.2 : 0.7))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .onAppear(perform: syncFromChannel)
    }
}

#if DEBUG
import AVFoundation

// Dummy Pitch struct and sample pitches for preview


// Minimal stub for preview engine
class PreviewFunctionGeneratorEngine: FunctionGeneratorEngine {
    init(previewChannel: Channel) {
        super.init(channelsCount: 0)
        self.channels = [previewChannel]
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        // Set up a format for AVAudioSourceNode
        let sampleRate = 44100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let previewChannel = Channel(format: format)
        previewChannel.waveform = .sine
        previewChannel.frequency = 440
        previewChannel.gain = 0.7
        previewChannel.isPlaying = false
        previewChannel.selectedPitch = pitchFrequencies.first

        let engine = PreviewFunctionGeneratorEngine(previewChannel: previewChannel)
        
        return ChannelView(channel: previewChannel, engine: engine)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
