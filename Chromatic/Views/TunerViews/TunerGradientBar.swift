//
//  TunerGradientBar.swift
//  Chromatic
//
//  Created by David Nyman on 7/18/25.
//


import SwiftUI

struct TunerGradientBar: View {
    var fillColor: Color
    var isFlat: Bool
    var isSharp: Bool

    var gradient: LinearGradient {
        if isFlat {
            return LinearGradient(
                gradient: Gradient(colors: [.white, fillColor]),
                startPoint: .leading, endPoint: .trailing
            )
        } else if isSharp {
            return LinearGradient(
                gradient: Gradient(colors: [fillColor, .white]),
                startPoint: .leading, endPoint: .trailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [fillColor, fillColor.opacity(0.8)]),
                startPoint: .leading, endPoint: .trailing
            )
        }
    }

    var body: some View {
        gradient
            .frame(height: 30)
            .cornerRadius(8)
            .shadow(radius: 3)
            .animation(.easeInOut(duration: 0.25), value: isFlat)
            .animation(.easeInOut(duration: 0.25), value: isSharp)
            .padding()
    }
}

// Example Preview
struct TunerGradientBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TunerGradientBar(fillColor: .yellow, isFlat: true, isSharp: false)
            TunerGradientBar(fillColor: .green, isFlat: false, isSharp: true)
            TunerGradientBar(fillColor: .purple, isFlat: false, isSharp: false)
        }
        .padding()
    }
}
