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
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .h4Style()
                .foregroundColor(isEnabled ? (style == .filled ? Color.white : Color.black) : Color.grey30)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? (style == .filled ? Color.black : Color.clear) : Color.grey10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.clear, lineWidth: 1)
                )
                .cornerRadius(5)
        }
        .disabled(!isEnabled)
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

