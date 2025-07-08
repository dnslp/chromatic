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
    private var harmonics: [Double] {
         (1...7).map { Double($0) * f0Hz }
     }
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isTextFocused: Bool
    @State private var editingText: String = ""

    // Formatter to ensure two decimals
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

                // Text field bound to internal string
                TextField("Hz", text: $editingText, onCommit: commitText)
                    .focused($isTextFocused)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .onAppear { editingText = String(format: "%.2f", f0Hz) }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                commitText()
                            }
                        }
                    }

                // Closest note and cent deviation
                Text("Closest: \(noteName) \(centOffset >= 0 ? "+" : "")\(centOffset, specifier: "%.1f")¢")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Slider updates both f0Hz and text when not editing
                VStack {
                    Text("Adjust with Slider")
                        .font(.headline)
                    Slider(value: $f0Hz, in: 20...500, step: 0.01)
                        .onChange(of: f0Hz) { new in
                            if !isTextFocused {
                                editingText = String(format: "%.2f", new)
                            }
                        }
                    Text("\(f0Hz, specifier: "%.2f") Hz")
                        .font(.title2)
                        .monospacedDigit()
                }
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
