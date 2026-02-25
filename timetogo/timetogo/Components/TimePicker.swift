//
//  TimePicker.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct TimePicker: View {
    var label: String
    @Binding var selectedValue: String
    
    @State private var showPicker = false
    @State private var selectedMinutes: Int = 0
    
    private let timeOptions: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20]
    
    init(label: String, selectedValue: Binding<String>) {
        self.label = label
        self._selectedValue = selectedValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .labelStyle()
                .foregroundColor(Color.black)
            
            // Time picker field
            Button {
                // Initialize selectedMinutes from selectedValue if not "Choose"
                if selectedValue != "Choose" {
                    let minutesString = selectedValue.replacingOccurrences(of: " min", with: "")
                    selectedMinutes = Int(minutesString) ?? timeOptions.first ?? 1
                } else {
                    selectedMinutes = timeOptions.first ?? 1
                }
                showPicker = true
            } label: {
                HStack {
                    Text(selectedValue)
                        .h4Style()
                        .foregroundColor(selectedValue == "Choose" ? Color.grey30 : Color.black)
                    
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
        .sheet(isPresented: $showPicker) {
            TimePickerModalView(
                title: label,
                timeOptions: timeOptions,
                selectedMinutes: $selectedMinutes,
                onDone: { minutes in
                    selectedValue = "\(minutes) min"
                    showPicker = false
                },
                onDismiss: {
                    showPicker = false
                }
            )
        }
    }
}

struct TimePickerModalView: View {
    var title: String
    var timeOptions: [Int]
    @Binding var selectedMinutes: Int
    var onDone: (Int) -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                Picker("Time", selection: $selectedMinutes) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        Text("\(minutes) min")
                            .tag(minutes)
                            .h4Style()
                            .foregroundColor(Color.black)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(Color.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone(selectedMinutes)
                    }
                    .foregroundColor(Color.black)
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTime = "Choose"
        
        var body: some View {
            TimePicker(
                label: "How long do you walk to tube?",
                selectedValue: $selectedTime
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
