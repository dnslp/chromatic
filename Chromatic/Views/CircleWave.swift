import SwiftUI

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

struct WaveCircleBorder: View {
    var strength: CGFloat = 10
    var frequency: CGFloat = 20
    var lineWidth: CGFloat = 3
    var color: Color = .green
    var animationDuration: Double = 2
    var autoreverses: Bool = false
    var height: CGFloat = 200
    var width: CGFloat = 200
    var reversed: Bool = false   // <--- Use Bool for direction

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)
            CircleWave(strength: strength, frequency: frequency, phase: phase)
                .stroke(color, lineWidth: lineWidth)
                .animation(
                    Animation.linear(duration: animationDuration)
                        .repeatForever(autoreverses: autoreverses),
                    value: phase
                )
        }
        .frame(width: width, height: height)
        .shadow(color: color.opacity(0.5), radius: 3, x: 1, y: 1)
        .onAppear {
            let direction: CGFloat = reversed ? -1 : 1
            phase = direction * .pi * 2
        }
    }
}

// MARK: - Preview
struct WaveCircleBorder_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            WaveCircleBorder(height: 100, width: 100)
            WaveCircleBorder(color: .red, height: 100, width: 100, reversed: true)
        }
        .padding()
    }
}
