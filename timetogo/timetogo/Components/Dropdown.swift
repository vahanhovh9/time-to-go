//
//  Dropdown.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

struct Dropdown<Item: Hashable>: View where Item: CustomStringConvertible {
    var label: String
    var items: [Item]
    @Binding var selectedItem: Item
    var onItemSelected: ((Item) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .labelStyle()
                .foregroundColor(Color.black)
            
            // Dropdown field
            Menu {
                ForEach(items, id: \.self) { item in
                    Button {
                        selectedItem = item
                        onItemSelected?(item)
                    } label: {
                        Text(item.description)
                            .h4Style()
                    }
                }
            } label: {
                HStack {
                    Text(selectedItem.description)
                        .h4Style()
                        .foregroundColor(Color.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.black)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(Color.grey10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.grey30, lineWidth: 1)
                )
                .cornerRadius(5)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedLine = "Northern line"
        
        var body: some View {
            Dropdown(
                label: "Your line",
                items: ["Northern line", "Central line", "Jubilee line", "Victoria line"],
                selectedItem: $selectedLine
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}

