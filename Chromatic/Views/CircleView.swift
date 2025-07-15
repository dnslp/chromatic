//
//  CircleView.swift
//  Chromatic
//
//  Created by David Nyman on 7/15/25.
//

import SwiftUI

/// A simplified visualizer showing concentric circles responding to pitch distance and amplitude.
struct CircleView: View {
    let distance: Double
    let maxDistance: Double
    let tunerData: TunerData
    let fundamentalHz: Double?
    
    // Fraction of in-tune accuracy (0–1)
    private var percent: Double {
        max(0, 1 - abs(distance) / maxDistance)
    }
    
    // Effective fundamental frequency
    private var f0: Double {
        fundamentalHz ?? tunerData.pitch.measurement.value
    }
    
    // Hue based on current pitch
    private var fillColor: Color {
        let hz = tunerData.pitch.measurement.value
        let midi = 69 + 12 * log2(hz / 440)
        let idx = (Int(round(midi)) % 12 + 12) % 12
        return Color(hue: Double(idx) / 12.0, saturation: 1, brightness: 1)
    }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let baseLineWidth = size * 0.05
            
            ZStack {
                // 1) Static backdrop ring
                Circle()
                    .stroke(fillColor.opacity(0.2), lineWidth: baseLineWidth)
                    .frame(width: size, height: size)
                
                // 2) Animated amplitude ring
                
            }
        }
    }
    
    struct CircleView_Previews: PreviewProvider {
        static var tunerSample = TunerData(pitch: 220, amplitude: 0.5)
        
        static var previews: some View {
            VStack(spacing: 20) {
                CircleView(
                    distance: 0,
                    maxDistance: 20,
                    tunerData: tunerSample,
                    fundamentalHz: 200
                )
                .frame(width: 200, height: 200)
                
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
}
