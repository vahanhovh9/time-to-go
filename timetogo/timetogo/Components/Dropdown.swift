//
//  Dropdown.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

struct Dropdown<Item: Hashable>: View where Item: CustomStringConvertible {
    var label: String
    var items: [Item]
    @Binding var selectedItem: Item
    var searchable: Bool = false
    var onItemSelected: ((Item) -> Void)?

    @State private var showModal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .labelStyle()
                .foregroundColor(Color.black)

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
                .padding(.horizontal, 24)
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
                searchable: searchable,
                onItemSelected: { item in
                    selectedItem = item
                    onItemSelected?(item)
                    showModal = false
                },
                onDismiss: {
                    showModal = false
                }
            )
            // Sheets must opt into light mode explicitly so NavigationView + List
            // use white chrome when the device is in Dark Mode.
            .preferredColorScheme(.light)
        }
    }
}

struct DropdownModalView<Item: Hashable>: View where Item: CustomStringConvertible {
    var title: String
    var items: [Item]
    @Binding var selectedItem: Item
    var searchable: Bool = false
    var onItemSelected: (Item) -> Void
    var onDismiss: () -> Void

    @State private var searchText = ""

    private var filteredItems: [Item] {
        guard searchable, !searchText.isEmpty else { return items }
        return items.filter {
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredItems, id: \.self) { item in
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
            .if(searchable) { view in
                view.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stations")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(Color.black)
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .preferredColorScheme(.light)
        }
        .navigationViewStyle(.stack)
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

