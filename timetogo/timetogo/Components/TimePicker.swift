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
        FormField(label: label, action: {
            // Start the wheel on the current value, or the first option when nothing is chosen.
            if selectedValue != "Choose" {
                let minutesString = selectedValue.replacingOccurrences(of: " min", with: "")
                selectedMinutes = Int(minutesString) ?? timeOptions.first ?? 1
            } else {
                selectedMinutes = timeOptions.first ?? 1
            }
            showPicker = true
        }) {
            FormFieldValue(text: selectedValue, isPlaceholder: selectedValue == "Choose")
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
            .preferredColorScheme(.light)
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
                            .scaledFont(size: 17, weight: .bold).tracking(-0.5)
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
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(Color.black)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.light)
        .presentationDetents([.height(300)])
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTime = "Choose"
        
        var body: some View {
            TimePicker(
                label: "How long is your walk to the tube?",
                selectedValue: $selectedTime
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
