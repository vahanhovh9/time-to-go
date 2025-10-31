//
//  DayPicker.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

struct DayPicker: View {
    var day: String
    @Binding var isSelected: Bool
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
            onTap?()
        }) {
            HStack {
                Text(day)
                    .h4Style()
                    .foregroundColor(isSelected ? Color.white : Color.black)
                
                Spacer()
                
                Checkmark(state: isSelected ? .checked : .unchecked)
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(isSelected ? Color.black : Color.grey10)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? Color.clear : Color.grey30, lineWidth: 1)
            )
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var monday = false
        @State private var tuesday = true
        @State private var wednesday = false
        
        var body: some View {
            VStack(spacing: 12) {
                DayPicker(day: "Monday", isSelected: $monday)
                DayPicker(day: "Tuesday", isSelected: $tuesday)
                DayPicker(day: "Wednesday", isSelected: $wednesday)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

