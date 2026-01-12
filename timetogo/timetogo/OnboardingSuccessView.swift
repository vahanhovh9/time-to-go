//
//  OnboardingSuccessView.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct OnboardingSuccessView: View {
    var onAllDone: () -> Void
    var onChangeSettings: () -> Void
    
    private var nextUpdateDate: String {
        // Calculate next Tuesday at 7:30 AM
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.weekday], from: today)
        let daysUntilTuesday = (3 - (components.weekday ?? 1) + 7) % 7
        var nextTuesday = calendar.date(byAdding: .day, value: daysUntilTuesday == 0 ? 7 : daysUntilTuesday, to: today) ?? today
        
        // Set time to 7:30 AM
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: nextTuesday)
        dateComponents.hour = 7
        dateComponents.minute = 30
        nextTuesday = calendar.date(from: dateComponents) ?? nextTuesday
        
        // Format date with ordinal suffix
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: nextTuesday)
        
        let day = calendar.component(.day, from: nextTuesday)
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let monthName = monthFormatter.string(from: nextTuesday)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: nextTuesday)
        let time = timeStr.replacingOccurrences(of: " am", with: " AM", options: .caseInsensitive)
                         .replacingOccurrences(of: " pm", with: " PM", options: .caseInsensitive)
        
        // Add ordinal suffix
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        return "\(dayName) \(day)\(suffix) \(monthName) at \(time)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (no step indicator, just centered title)
            OnboardingHeader(
                step: nil,
                totalSteps: nil,
                title: "Awesome all set up!"
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Content
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Party popper emoji
                    Text("🎉")
                        .font(.system(size: 80))
                    
                    // Next update info card
                    VStack(alignment: .center, spacing: 12) {
                        Text("Next update")
                            .h4Style()
                            .foregroundColor(Color.black)
                        
                        Text(nextUpdateDate)
                            .labelStyle()
                            .foregroundColor(Color.grey30)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Footer with buttons
            VStack(spacing: 16) {
                CustomButton(title: "All done", style: .filled) {
                    onAllDone()
                }
                
                CustomButton(title: "Change your settings", style: .outline) {
                    onChangeSettings()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                // Background color fallback
                Color.yellow
                
                // Background image
                Image("bg-main")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        )
    }
}

#Preview {
    OnboardingSuccessView(
        onAllDone: { print("All done tapped") },
        onChangeSettings: { print("Change settings tapped") }
    )
}
