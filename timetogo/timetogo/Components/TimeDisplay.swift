//
//  TimeDisplay.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct TimeDisplay: View {
    var time: String
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Spacer()
                Circle()
                    .fill(Color.white)
                    .frame(width: 228, height: 228)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    )
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black)
                .frame(height: 104)
                .overlay(
                    Text(time)
                        .timeStyle()
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 26)
                )
                .padding(.horizontal, -0.5)
                .padding(.top, 61)
        }
        .frame(width: 369, height: 228, alignment: .top)
    }
}

#Preview {
    TimeDisplay(time: "12:59 AM")
        .padding()
        .background(Color.white)
}


