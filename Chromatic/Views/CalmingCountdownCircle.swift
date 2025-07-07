import SwiftUI

struct CalmingCountdownCircle: View {
    let secondsLeft: Int
    let totalSeconds: Int

    var percent: Double {
        1.0 - Double(secondsLeft - 1) / Double(totalSeconds)
    }

    @State private var animatePulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(gradient: Gradient(colors: [
                        Color.blue.opacity(0.18),
                        Color.purple.opacity(0.12)
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .scaleEffect(animatePulse ? 1.04 : 1)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animatePulse)
                .onAppear { animatePulse = true }
            Circle()
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [
                        Color.blue.opacity(0.2),
                        Color.blue.opacity(0.5),
                        Color.purple.opacity(0.6),
                        Color.blue.opacity(0.2)
                    ]), center: .center),
                    lineWidth: 8
                )
            Circle()
                .trim(from: 0, to: percent)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: percent)
        }
    }
}

struct CalmingCountdownCircle_Previews: PreviewProvider {
    static var previews: some View {
        CalmingCountdownCircle(secondsLeft: 3, totalSeconds: 7)
            .frame(width: 140, height: 140)
    }
}
