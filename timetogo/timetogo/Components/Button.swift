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
    /// No background or border — secondary action under a filled button.
    case text
}

struct CustomButton: View {
    var title: String
    var style: ButtonStyle
    var action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            // Figma "Button": 48pt tall, 10pt corners, H5 label.
            Text(title)
                .typography(.h5)
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(style == .outline && isEnabled ? Color.black : Color.clear, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!isEnabled)
    }

    private var foreground: Color {
        guard isEnabled else { return .grey30 }
        return style == .filled ? .white : .black
    }

    private var background: Color {
        guard isEnabled else { return style == .text ? .clear : .grey10 }
        return style == .filled ? .black : .clear
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(title: "Next", style: .filled) {
            print("Filled button tapped")
        }
        
        CustomButton(title: "Change your settings", style: .outline) {
            print("Outline button tapped")
        }
    }
    .padding()
}

