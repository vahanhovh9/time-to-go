//
//  TimeDisplay.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct TimeDisplay: View {
    var day: String
    var time: String
    
    var body: some View {
        ZStack {
            // White circle with black border
            Circle()
                .fill(Color.white)
                .frame(width: 228, height: 228)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                )
            
            // Black Timeboard rectangle - centered vertically and horizontally
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black)
                .frame(width: 369, height: 149)
                .overlay(
                    VStack(spacing: 10) {
                        Text(day)
                            .bodyTextStyle()
                            .foregroundColor(Color.white)
                            .padding(.top, 24)
                        
                        Text(time)
                            .timeStyle()
                            .foregroundColor(Color.white)
                            .padding(.top, -16)
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                )
        }
        .frame(width: 369, height: 228)
    }
}

#Preview {
    TimeDisplay(day: "Today at", time: "12:59 AM")
        .padding()
        .background(Color.white)
}


