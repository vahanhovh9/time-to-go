//
//  TimeDisplay.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

/// Large time readout. Scales down with available width so parent horizontal padding
/// (e.g. 24pt on MainView) is respected — fixed 369pt would overflow typical phone widths.
struct TimeDisplay: View {
    var day: String
    var time: String

    /// Design-size reference (iPhone-wide layout at 1:1 scale).
    private let designWidth: CGFloat = 369
    private let designHeight: CGFloat = 228

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let scale = w / designWidth

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 228 * scale, height: 228 * scale)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 10 * scale)
                    .fill(Color.black)
                    .frame(width: designWidth * scale, height: 149 * scale)
                    .overlay(
                        VStack(spacing: 10 * scale) {
                            Text(day)
                                .bodyTextStyle()
                                .foregroundColor(Color.white)
                                .padding(.top, 24 * scale)

                            Text(time)
                                .timeStyle()
                                .foregroundColor(Color.white)
                                .padding(.top, -16 * scale)
                        }
                        .padding(.horizontal, 26 * scale)
                        .padding(.top, 14 * scale)
                        .padding(.bottom, 28 * scale)
                    )
            }
            .frame(width: w, height: designHeight * scale)
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(designWidth / designHeight, contentMode: .fit)
    }
}

#Preview {
    TimeDisplay(day: "Today at", time: "12:59 AM")
        .padding(.horizontal, 24)
        .background(Color.white)
}
