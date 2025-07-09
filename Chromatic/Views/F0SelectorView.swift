import SwiftUI

/// A button that shows the current f₀ value and presents a modal editor when tapped.
struct F0SelectorView: View {
    @Binding var f0Hz: Double
    @State private var showingEditor = false
    
    private var harmonics: [Double] {
         (1...7).map { Double($0) * f0Hz }
     }

    var body: some View {
        Button(action: { showingEditor = true }) {
            HStack(spacing: 8) {
                Text("f₀: \(f0Hz, specifier: "%.2f") Hz")
                    .font(.body.weight(.medium))
                Image(systemName: "pencil.circle")
                    .font(.title2)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .sheet(isPresented: $showingEditor) {
            F0EditorView(f0Hz: $f0Hz)
        }
    }
}

/// Modal editor for f₀, with number pad entry and precise slider.
/// Allows free text editing without slider overriding input, and shows closest note + cent deviation.
struct F0EditorView: View {
    @Binding var f0Hz: Double
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isTextFocused: Bool
    @State private var editingText: String = ""
    @State private var selectedPitch: PitchOption? = nil

    // Generate options (C2–B5, adjust octaves as desired)
    struct PitchOption: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let frequency: Double
    }
    private static let pitchOptions: [PitchOption] = {
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        var options = [PitchOption]()
        for octave in 1...6 {
            for (i, name) in noteNames.enumerated() {
                let midi = octave * 12 + i
                let freq = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                options.append(PitchOption(name: "\(name)\(octave)", frequency: freq))
            }
        }
        return options.sorted { $0.frequency < $1.frequency }
    }()
    private var pitchOptions: [PitchOption] { Self.pitchOptions }

    private var harmonics: [Double] { (1...7).map { Double($0) * f0Hz } }
    private let hzFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    // Computed closest note and cent distance
    private var f0Freq: Frequency { Frequency(floatLiteral: f0Hz) }
    private var match: ScaleNote.Match { ScaleNote.closestNote(to: f0Freq) }
    private var noteName: String { "\(match.note)" }
    private var centOffset: Double { Double(match.distance.cents) }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                HStack {
                    Text("Enter f₀ (Hz)")
                        .font(.headline)
                    Spacer()
                }

                // Editable TextField
                TextField("Hz", text: $editingText, onCommit: commitText)
                    .focused($isTextFocused)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .onAppear {
                        editingText = String(format: "%.2f", f0Hz)
                        selectedPitch = pitchOptions.min(by: { abs($0.frequency - f0Hz) < abs($1.frequency - f0Hz) })
                    }
                    .onChange(of: f0Hz) { newHz in
                        if !isTextFocused {
                            editingText = String(format: "%.2f", newHz)
                        }
                        selectedPitch = pitchOptions.min(by: { abs($0.frequency - newHz) < abs($1.frequency - newHz) })
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { commitText() }
                        }
                    }

                // Dropdown Picker for pitch
                Picker("Choose Pitch", selection: $selectedPitch) {
                    ForEach(pitchOptions) { option in
                        Text("\(option.name) (\(option.frequency, specifier: "%.2f") Hz)").tag(Optional(option))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedPitch) { newValue in
                    if let selected = newValue {
                        f0Hz = selected.frequency
                        editingText = String(format: "%.2f", selected.frequency)
                    }
                }

                // Closest note and cent deviation
                Text("Closest: \(noteName) \(centOffset >= 0 ? "+" : "")\(centOffset, specifier: "%.1f")¢")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Harmonics:")
                        .font(.headline)
                    ForEach(Array(harmonics.enumerated()), id: \.offset) { i, hz in
                        Text("f\(i + 1): \(hz, specifier: "%.2f") Hz")
                            .font(.caption.monospacedDigit())
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Select f₀")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commitText()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func commitText() {
        if let val = hzFormatter.number(from: editingText)?.doubleValue {
            f0Hz = val
            selectedPitch = pitchOptions.min(by: { abs($0.frequency - val) < abs($1.frequency - val) })
        }
        isTextFocused = false
    }
}


struct F0SelectorView_Previews: PreviewProvider {
    @State static var previewHz: Double = 77.78

    static var previews: some View {
        F0SelectorView(f0Hz: $previewHz)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
