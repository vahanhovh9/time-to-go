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
            HStack(spacing: 8) {
                Text(day)
                    .typography(.h4)
                    .foregroundColor(isSelected ? .white : .grey50)
                Spacer(minLength: 0)
                Checkmark(state: isSelected ? .checked : .unchecked)
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .frame(minHeight: 48)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.black : Color.grey10)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Compact day toggle for a row of five (Figma: setup step 3): grey when off, black with
/// green text when on.
struct DayChip: View {
    var day: String
    @Binding var isSelected: Bool

    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            Text(day)
                .typography(.h4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(isSelected ? .brightGreen : .grey50)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(isSelected ? Color.black : Color.grey10)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

