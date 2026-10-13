//
//  ArrivalTimePicker.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct ArrivalTimePicker: View {
    var label: String
    @Binding var selectedTime: Date
    var maximumTime: Date? = nil
    @State private var showPicker = false

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeStr = formatter.string(from: selectedTime)
        return timeStr.lowercased()
    }

    init(label: String, selectedTime: Binding<Date>, maximumTime: Date? = nil) {
        self.label = label
        self._selectedTime = selectedTime
        self.maximumTime = maximumTime
    }
    
    var body: some View {
        FormField(label: label, action: { showPicker = true }) {
            FormFieldValue(text: timeString, isPlaceholder: false)
        }
        .sheet(isPresented: $showPicker) {
            ArrivalTimePickerModalView(
                title: label,
                selectedTime: $selectedTime,
                maximumTime: maximumTime,
                onDone: { showPicker = false },
                onDismiss: { showPicker = false }
            )
            .preferredColorScheme(.light)
        }
    }
}

struct ArrivalTimePickerModalView: View {
    var title: String
    @Binding var selectedTime: Date
    var maximumTime: Date? = nil
    var onDone: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                if let max = maximumTime {
                    DatePicker(
                        "Time",
                        selection: $selectedTime,
                        in: ...max,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                } else {
                    DatePicker(
                        "Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                }
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
                        onDone()
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
        @State private var selectedTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        var body: some View {
            ArrivalTimePicker(
                label: "Arrival time",
                selectedTime: $selectedTime
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
