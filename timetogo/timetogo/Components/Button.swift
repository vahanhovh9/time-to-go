//
//  Button.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

enum ButtonStyle {
    case filled
    case outline
}

struct CustomButton: View {
    var title: String
    var style: ButtonStyle
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .h4Style()
                .foregroundColor(style == .filled ? Color.white : Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(style == .filled ? Color.black : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.clear, lineWidth: 1)
                )
                .cornerRadius(5)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(title: "Next", style: .filled) {
            print("Filled button tapped")
        }
        
        CustomButton(title: "Change you settings", style: .outline) {
            print("Outline button tapped")
        }
    }
    .padding()
}

