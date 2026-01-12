//
//  Onboarding4View.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct Onboarding4View: View {
    @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    
    var onComplete: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingHeader(
                step: 4,
                totalSteps: 4,
                title: "When get notified?",
                showsBackButton: true,
                onBack: onBack
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)
                    
                    // Pick a time picker (same component as Onboarding 3 for consistency)
                    ArrivalTimePicker(
                        label: "Pick a time",
                        selectedTime: $notificationTime
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Footer with button
            VStack(spacing: 0) {
                Divider()
                    .background(Color.grey10)
                
                VStack(spacing: 16) {
                    CustomButton(title: "Complete", style: .filled) {
                        onComplete()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color.white)
        }
        .background(Color.white)
    }
}

#Preview {
    Onboarding4View(
        onComplete: { print("Onboarding completed") },
        onBack: { print("Back tapped") }
    )
}
