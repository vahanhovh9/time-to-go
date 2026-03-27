//
//  Onboarding3View.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct Onboarding3View: View {
    @Binding var arrivalTime: Date
    @Binding var monday: Bool
    @Binding var tuesday: Bool
    @Binding var wednesday: Bool
    @Binding var thursday: Bool
    @Binding var friday: Bool
    
    var onNext: () -> Void
    var onBack: () -> Void
    
    private var isFormValid: Bool {
        monday || tuesday || wednesday || thursday || friday
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingHeader(
                step: 3,
                totalSteps: 4,
                title: "When at office?",
                showsBackButton: true,
                onBack: onBack
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)
                    
                    // Arrival time picker
                    ArrivalTimePicker(
                        label: "Arrival time",
                        selectedTime: $arrivalTime
                    )
                    .padding(.horizontal, 24)
                    
                    // Day pickers in 2-column grid (Monday-Friday only)
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        // Row 1: Monday, Tuesday
                        DayPicker(day: "Monday", isSelected: $monday)
                        DayPicker(day: "Tuesday", isSelected: $tuesday)
                        
                        // Row 2: Wednesday, Thursday
                        DayPicker(day: "Wednesday", isSelected: $wednesday)
                        DayPicker(day: "Thursday", isSelected: $thursday)
                        
                        // Row 3: Friday, empty space
                        DayPicker(day: "Friday", isSelected: $friday)
                        // Empty space - invisible spacer
                        Color.clear
                            .frame(height: 56)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Footer with button
            VStack(spacing: 0) {
                Divider()
                    .background(Color.grey10)
                
                VStack(spacing: 16) {
                    CustomButton(title: "Next", style: .filled, action: { onNext() }, isEnabled: isFormValid)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .background(Color.white)
        }
        .background(Color.white)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var arrivalTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        @State private var monday = false
        @State private var tuesday = true
        @State private var wednesday = false
        @State private var thursday = true
        @State private var friday = false
        
        var body: some View {
            Onboarding3View(
                arrivalTime: $arrivalTime,
                monday: $monday,
                tuesday: $tuesday,
                wednesday: $wednesday,
                thursday: $thursday,
                friday: $friday,
                onNext: { print("Next tapped") },
                onBack: { print("Back tapped") }
            )
        }
    }
    
    return PreviewWrapper()
}
