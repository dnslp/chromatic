import SwiftUI

struct MatchedNoteView: View {
    let match: ScaleNote.Match
    @State var modifierPreference: ModifierPreference
    @State private var animateSolid = false
    @State private var gradientRotation = Angle.degrees(0)



    // MARK: — Border styles
    private enum BorderType {
        case solid            // ±5¢
        case borderFlat       // –15…–5¢
        case borderSharp      // +5…+15¢
        case borderFlatter   // –30…–15¢
        case borderSharper  // +15…+30¢
        case borderFlattest     // < –30¢
        case borderSharpest    // > +30¢
    }

    private var borderType: BorderType {
        let cents = Double(match.distance.cents)

        switch cents {
        case -5.0...5.0:
            return .solid

        case -15.0..<(-5.0):
            return .borderFlat
        case 5.0..<15.0:
            return .borderSharp

        case -30.0..<(-15.0):
            return .borderFlatter
        case 15.0..<30.0:
            return .borderSharper

        case ..<(-30.0):
            return .borderFlattest
        case 30.0...:
            return .borderSharpest

        default:
            return .solid
        }
    }

    // MARK: — Pitch → Hue mapping (0…1 from C→B)
    private var pitchHue: Double {
        let total = Double(ScaleNote.allCases.count)
        let idx   = Double(ScaleNote.allCases.firstIndex(of: match.note) ?? 0)
        return idx / total
    }

    // MARK: — Foreground color varies brightness by cent-error
    private var fgColor: Color {
        let cents = abs(Double(match.distance.cents))
        let brightness: Double
        switch cents {
        case ...5:   brightness = 1.0    // In tune
        case ...15:  brightness = 0.8    // Slightly off
        default:     brightness = 0.6    // Far off
        }
        return Color(hue: pitchHue, saturation: 1, brightness: brightness)
    }

    // MARK: — Base border color (full hue, adjust opacity)
    private var borderColor: Color {
        let cents = abs(Double(match.distance.cents))
        let opacity: Double
        switch cents {
        case ...5:   opacity = 1.0
        case ...15:  opacity = 0.6
        case ...30:  opacity = 0.4
        default:     opacity = 0.3
        }
        return Color(hue: pitchHue, saturation: 1, brightness: 1)
            .opacity(opacity)
    }

    // MARK: — Background tint
    private var bgColor: Color {
        fgColor.opacity(0.15)
    }

    // MARK: — Note naming
    private var preferredName: String {
        modifierPreference == .preferSharps
            ? match.note.names.first!
            : match.note.names.last!
    }
    private var baseNote: String { String(preferredName.prefix(1)) }
    private var accidental: String? {
        preferredName.count > 1 ? String(preferredName.suffix(1)) : nil
    }

    var body: some View {
        ZStack(alignment: .noteModifier) {
            
            HStack(alignment: .lastTextBaseline) {
                Text(baseNote)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(fgColor)
                    .animation(nil, value: match.note)
                
                Text("\(match.octave)")
                    .font(.system(size: 20, design: .rounded))
                    .foregroundColor(.secondary)
                    .alignmentGuide(.octaveCenter) { dims in
                        dims[HorizontalAlignment.center]
                    }
            }.frame(width: 120, height: 120)
            
            if let mod = accidental {
                Text(mod)
                    .font(.system(size: 50, design: .rounded))
                    .foregroundColor(fgColor)
                    .baselineOffset(-2)
                    .alignmentGuide(.octaveCenter) { dims in
                        dims[HorizontalAlignment.center]
                    }
            }
        }
        .padding(.all, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
        )
        .overlay(
            Group {
                switch borderType {
                case .solid:
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    borderColor.opacity(0.6),
                                    borderColor.opacity(1.0),
                                    borderColor.opacity(0.6)
                                ]),
                                center: .center,
                                startAngle: gradientRotation,
                                endAngle: gradientRotation + .degrees(360)
                            ),
                            lineWidth: 5
                        )
                        // ← glowing shadow that pulses
                        .shadow(color: borderColor.opacity(1),
                                radius: animateSolid ? 10 : 1,
                                x: 0, y: 0)
                        .onAppear {
                            // 1) spin the gradient
                            // 2) pulse the glow
                            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: true)) {
                                animateSolid.toggle()
                            }
                        }

                    
                case .borderFlat:
                    // simple double‐line flat style
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        borderColor.opacity(0.6),
                                        borderColor.opacity(1.0),
                                        borderColor.opacity(0.6)
                                    ]),
                                    center: .center,
                                    startAngle: gradientRotation,
                                    endAngle: gradientRotation + .degrees(360)
                                ),
                                lineWidth: 5
                            )
                    }                        .onAppear {
                        // spin it forever at a constant speed
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            gradientRotation = .degrees(360)
                        }
                    }
                    
                case .borderFlatter:
                    // light flat gradient: very faint bottom → medium top
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    borderColor.opacity(0.3),
                                    borderColor.opacity(1.0),
                                    borderColor.opacity(0.3)
                                ]),
                                center: .center,
                                startAngle: gradientRotation,
                                endAngle: gradientRotation + .degrees(360)
                            ),
                            lineWidth: 5
                        ).onAppear {
                            // spin it forever at a constant speed
                            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                gradientRotation = .degrees(360)
                            }
                        }
                    
                case .borderFlattest:
                    // stronger flat gradient: faint bottom → full top
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    borderColor.opacity(0.3),
                                    borderColor.opacity(1.0),
                                    borderColor.opacity(0.3)
                                ]),
                                center: .center,
                                startAngle: gradientRotation,
                                endAngle: gradientRotation + .degrees(360)
                            ),
                            lineWidth: 5
                        ).onAppear {
                            // spin it forever at a constant speed
                            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                                gradientRotation = .degrees(360)
                            }
                        }
                    
                case .borderSharp:
                    // simple double‐line sharp style
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        borderColor.opacity(0.6),
                                        borderColor.opacity(1.0),
                                        borderColor.opacity(0.6)
                                    ]),
                                    center: .center,
                                    startAngle: gradientRotation,
                                    endAngle: gradientRotation + .degrees(360)
                                ),
                                lineWidth: 5
                            )
                    }                        .onAppear {
                        // spin it forever at a constant speed
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            gradientRotation = .degrees(-360)
                        }
                    }
                    
                case .borderSharper:
                    // moderate sharp gradient: medium bottom → fuller top
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    borderColor.opacity(0.3),
                                    borderColor.opacity(1.0),
                                    borderColor.opacity(0.3)
                                ]),
                                center: .center,
                                startAngle: gradientRotation,
                                endAngle: gradientRotation + .degrees(360)
                            ),
                            lineWidth: 5
                        ).onAppear {
                            // spin it forever at a constant speed
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                gradientRotation = .degrees(-360)
                            }
                        }
                    
                case .borderSharpest:
                    // strongest sharp gradient: heavy bottom → full top
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    borderColor.opacity(0.1),
                                    borderColor.opacity(1.0),
                                    borderColor.opacity(0.1)
                                ]),
                                center: .center,
                                startAngle: gradientRotation,
                                endAngle: gradientRotation + .degrees(360)
                            ),
                            lineWidth: 5
                        ).onAppear {
                            // spin it forever at a constant speed
                            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                                gradientRotation = .degrees(-360)
                            }
                        }
                }
            }
        )

        .animation(.easeInOut, value: match.distance.cents)
        .onTapGesture {
            modifierPreference = modifierPreference == .preferSharps
                ? .preferFlats
                : .preferSharps
        }
    }
}

struct MatchedNoteView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MatchedNoteView(
                match: .init(note: .CSharp_DFlat, octave: 4, distance: 0),
                modifierPreference: .preferSharps
            )
            .previewDisplayName("In Tune")

            MatchedNoteView(
                match: .init(note: .A, octave: 4, distance: 10),
                modifierPreference: .preferSharps
            )
            .previewDisplayName("Slightly Sharp")
            
            MatchedNoteView(
                match: .init(note: .A, octave: 4, distance: 15),
                modifierPreference: .preferSharps
            )
            .previewDisplayName("More Sharp")
            MatchedNoteView(
                match: .init(note: .A, octave: 4, distance: 30),
                modifierPreference: .preferSharps
            )
            .previewDisplayName("Really Sharp")

            MatchedNoteView(
                match: .init(note: .F, octave: 3, distance: -15),
                modifierPreference: .preferFlats
            )
            .previewDisplayName("Flat")
            MatchedNoteView(
                match: .init(note: .F, octave: 3, distance: -10),
                modifierPreference: .preferFlats
            )
            .previewDisplayName("Flatter")

            MatchedNoteView(
                match: .init(note: .F, octave: 3, distance: -30),
                modifierPreference: .preferFlats
            )
            .previewDisplayName("Flattest")
        }
        .previewLayout(.sizeThatFits)
    }
}
