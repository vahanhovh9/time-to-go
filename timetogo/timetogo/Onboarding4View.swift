//
//  Onboarding4View.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct Onboarding4View: View {
    @Binding var notificationTime: Date
    /// The arrival time from step 3 — notification must be at most 30 min before it.
    var arrivalTime: Date

    var onComplete: () -> Void
    var onBack: () -> Void

    /// Latest allowed notification time = arrivalTime − 30 min, expressed as today's date.
    private var maxNotificationTime: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: arrivalTime.addingTimeInterval(-30 * 60))
        return cal.date(bySettingHour: comps.hour ?? 8, minute: comps.minute ?? 30, second: 0, of: Date()) ?? Date()
    }
    
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
            .padding(.top, 68)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)
                    
                    // Pick a time picker (same component as Onboarding 3 for consistency)
                    ArrivalTimePicker(
                        label: "Pick a time",
                        selectedTime: $notificationTime,
                        maximumTime: maxNotificationTime
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
                .padding(.top, 20)
                .padding(.bottom, 56)
            }
            .background(Color.white)
        }
        .background(Color.white)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
        
        var body: some View {
            Onboarding4View(
                notificationTime: $notificationTime,
                arrivalTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
                onComplete: { print("Onboarding completed") },
                onBack: { print("Back tapped") }
            )
        }
    }
    
    return PreviewWrapper()
}
