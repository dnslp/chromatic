import SwiftUI

/// A circle whose radius is modulated by a wave function with uniform amplitude.
struct CircleWave: Shape {
    var strength: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2
        let steps = 200
        let twoPi = CGFloat.pi * 2

        var path = Path()
        for i in 0...steps {
            let pct = CGFloat(i) / CGFloat(steps)
            let angle = pct * twoPi

            // Uniform wave amplitude (no tapering)
            let displacement = sin(angle * frequency + phase) * strength
            let radius = baseRadius + displacement

            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

/// A SwiftUI view that draws a circle with an animated, continuously-moving border.
struct WaveCircleBorder: View {
    /// How far the wave pushes in/out.
    var strength: CGFloat = 10
    /// Number of wave bumps around the circle.
    var frequency: CGFloat = 20
    /// Width of the border stroke.
    var lineWidth: CGFloat = 3
    /// Color of the animated border.
    var color: Color = .green
    /// Duration of one full wave cycle.
    var animationDuration: Double = 2
    /// Whether the animation should autoreverse (ignored when false).
    var autoreverses: Bool = false

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Faded static outline
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)

            // Animated wavy outline with uniform amplitude
            CircleWave(strength: strength, frequency: frequency, phase: phase)
                .stroke(color, lineWidth: lineWidth)
                .animation(
                    Animation.linear(duration: animationDuration)
                        .repeatForever(autoreverses: autoreverses),
                    value: phase
                )
        }
        .frame(width: 110, height: 110)
        .shadow(color: color.opacity(0.5), radius: 3, x: 1, y: 1)
        .onAppear {
            // Start the wave motion
            phase = .pi * 2
        }
    }
}

// MARK: - Preview
struct WaveCircleBorder_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            WaveCircleBorder()
            WaveCircleBorder(strength: 1, frequency: 70, lineWidth: 4, color: .red, animationDuration: 1, autoreverses: false)
        }
        .padding()
    }
}
