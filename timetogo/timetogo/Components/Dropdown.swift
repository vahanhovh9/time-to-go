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
    
    @State private var showModal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .labelStyle()
                .foregroundColor(Color.black)
            
            // Dropdown field
            Button {
                showModal = true
            } label: {
                HStack {
                    Text(selectedItem.description)
                        .h4Style()
                        .foregroundColor(selectedItem.description == "Choose" ? Color.grey30 : Color.black)
                    
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
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showModal) {
            DropdownModalView(
                title: label,
                items: items,
                selectedItem: $selectedItem,
                onItemSelected: { item in
                    selectedItem = item
                    onItemSelected?(item)
                    showModal = false
                },
                onDismiss: {
                    showModal = false
                }
            )
        }
    }
}

struct DropdownModalView<Item: Hashable>: View where Item: CustomStringConvertible {
    var title: String
    var items: [Item]
    @Binding var selectedItem: Item
    var onItemSelected: (Item) -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    Button {
                        onItemSelected(item)
                    } label: {
                        HStack {
                            Text(item.description)
                                .labelStyle()
                                .foregroundColor(Color.black)
                            
                            Spacer()
                            
                            if item == selectedItem {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.black)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(Color.black)
                }
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

