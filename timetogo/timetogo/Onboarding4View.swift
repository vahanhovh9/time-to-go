//
//  Onboarding4View.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct Onboarding4View: View {
    @Binding var notificationTime: Date
    @Binding var homeNotificationTime: Date
    /// The office arrival time from step 3 — office notification must be at most 30 min before it.
    var arrivalTime: Date
    /// The home arrival time from step 3 — home notification must be at most 30 min before it.
    var homeArrivalTime: Date

    var onComplete: () -> Void
    var onBack: () -> Void

    private var maxNotificationTime: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: arrivalTime.addingTimeInterval(-30 * 60))
        return cal.date(bySettingHour: comps.hour ?? 8, minute: comps.minute ?? 30, second: 0, of: Date()) ?? Date()
    }

    private var maxHomeNotificationTime: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: homeArrivalTime.addingTimeInterval(-30 * 60))
        return cal.date(bySettingHour: comps.hour ?? 17, minute: comps.minute ?? 30, second: 0, of: Date()) ?? Date()
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
            .padding(.horizontal, 24)
            .padding(.top, 48)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    ArrivalTimePicker(
                        label: "For office",
                        selectedTime: $notificationTime,
                        maximumTime: maxNotificationTime
                    )
                    .padding(.horizontal, 24)

                    ArrivalTimePicker(
                        label: "For home",
                        selectedTime: $homeNotificationTime,
                        maximumTime: maxHomeNotificationTime
                    )
                    .padding(.horizontal, 24)

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
        @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
        @State private var homeNotificationTime: Date = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()

        var body: some View {
            Onboarding4View(
                notificationTime: $notificationTime,
                homeNotificationTime: $homeNotificationTime,
                arrivalTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
                homeArrivalTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
                onComplete: { print("Onboarding completed") },
                onBack: { print("Back tapped") }
            )
        }
    }

    return PreviewWrapper()
}
