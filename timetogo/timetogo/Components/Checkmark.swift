//
//  Checkmark.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

enum CheckmarkState {
    case unchecked
    case checked
}

struct Checkmark: View {
    var state: CheckmarkState
    
    var body: some View {
        switch state {
        case .unchecked:
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                )
        
        case .checked:
            ZStack {
                Circle()
                    .fill(Color(red: 0.246, green: 0.921, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                // Checkmark path
                Path { path in
                    path.move(to: CGPoint(x: 5, y: 15))
                    path.addLine(to: CGPoint(x: 9, y: 19))
                    path.addLine(to: CGPoint(x: 19, y: 9))
                }
                .stroke(Color(red: 0.021, green: 0.565, blue: 0.075), lineWidth: 4)
                .frame(width: 24, height: 24)
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        Checkmark(state: .unchecked)
        Checkmark(state: .checked)
    }
    .padding()
}

