//
//  GeneratorView.swift
//  Chromatic
//
//  Created by David Nyman on 7/9/25.
//


import SwiftUI

struct GeneratorView: View {
    // MARK: – Algorithm State
    @State private var path: Path = Path()
    @State private var resolution: Double = 10
    @State private var angleMultiplier: Double = 2 * Double.pi
    @State private var scale: Double = 0.004

    // Sheet for tweaking parameters
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 28) {
            // ------- Header Bar -------
            HStack {
                Text("Flowing Fields")
                    .font(.headline)
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            // ------- Canvas -------
            GeometryReader { geometry in
                let width = max(geometry.size.width, geometry.size.height)
                // Draw the computed path
                pathway(
                    randomPos: randomPos(width: width),
                    res: resolution,
                    angle: angleMultiplier
                )
                .stroke(Color.primary, lineWidth: 1)
                .drawingGroup()
                .background(Color(white: 0.95))
            }

            // ------- Regenerate / Clear Controls -------
            HStack(spacing: 18) {
                Button("Regenerate") {
                    regenerate()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Clear") {
                    path = Path()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                resolution: $resolution,
                scale: $scale,
                angleMultiplier: $angleMultiplier
            )
        }
        .onAppear {
            regenerate()
        }
    }

    // MARK: – Regeneration
    private func regenerate() {
        // Trigger a fresh path with current parameters
        let width = UIScreen.main.bounds.width
        let randomPositions = randomPos(width: width)
        path = pathway(randomPos: randomPositions, res: resolution, angle: angleMultiplier)
    }

    // MARK: – Core Functions :contentReference[oaicite:1]{index=1}
    func randomPos(width: CGFloat) -> [[(Int,Int)]] {
        var posMatrix: [[(Int,Int)]] = []
        for _ in 0..<Int(width) {
            var row: [(Int,Int)] = []
            for _ in 0..<Int(width) {
                let x = Int.random(in: 0..<Int(width))
                let y = Int.random(in: 0..<Int(width))
                row.append((x,y))
            }
            posMatrix.append(row)
        }
        return posMatrix
    }

    func getAngle(randomPosCoord: (Int,Int), angle: Double) -> Double {
        return curlsFunc(randomPosCoord: randomPosCoord) * angle
    }

    func curlsFunc(randomPosCoord: (Int,Int)) -> Double {
        let x = Double(randomPosCoord.0) * scale
        let y = Double(randomPosCoord.1) * scale
        let t = x + y
        return (sin(t) * cos(t)) * Double.pi
    }

    func rotateCenter(x: CGFloat, y: CGFloat, center: CGPoint, angleR: Double) -> CGPoint {
        let transform = CGAffineTransform
            .identity
            .translatedBy(x: center.x, y: center.y)
            .rotated(by: angleR)
        return CGPoint(x: x, y: y).applying(transform)
    }

    func pathway(randomPos: [[(Int,Int)]], res: Double, angle: Double) -> Path {
        Path { p in
            for x in stride(from: 0, to: randomPos.count, by: Int(res)) {
                for y in stride(from: 0, to: randomPos[x].count, by: Int(res)) {
                    let coord = randomPos[x][y]
                    let start = CGPoint(x: coord.0, y: coord.1)
                    p.move(to: start)
                    let θ = getAngle(randomPosCoord: coord, angle: angle)
                    // Example line length; you can expose this as another parameter
                    let dx = 20 * cos(θ)
                    p.addLine(to: rotateCenter(
                        x: dx,
                        y: 0,
                        center: start,
                        angleR: θ
                    ))
                }
            }
        }
    }
}

// MARK: – Settings Sheet
struct SettingsView: View {
    @Binding var resolution: Double
    @Binding var scale: Double
    @Binding var angleMultiplier: Double

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grid Resolution")) {
                    Slider(value: $resolution, in: 5...50, step: 1) {
                        Text("Resolution")
                    }
                    Text("\(Int(resolution)) px")
                }
                Section(header: Text("Noise Scale")) {
                    Slider(value: $scale, in: 0.001...0.01, step: 0.001) {
                        Text("Scale")
                    }
                    Text(String(format: "%.3f", scale))
                }
                Section(header: Text("Angle Multiplier")) {
                    Slider(value: $angleMultiplier, in: 0...(.pi * 4), step: 0.1) {
                        Text("Angle")
                    }
                    Text(String(format: "%.2fπ", angleMultiplier / .pi))
                }
            }
            .navigationTitle("Parameters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController?.dismiss(animated: true) }
                }
            }
        }
    }
}
