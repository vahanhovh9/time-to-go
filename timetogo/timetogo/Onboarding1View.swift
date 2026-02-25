//
//  Onboarding1View.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct Onboarding1View: View {
    @Binding var selectedLine: String
    @Binding var selectedStation: String
    @Binding var selectedWalkTime: String
    
    var onNext: () -> Void = {}
    
    private var isFormValid: Bool {
        selectedStation != "Choose" && selectedWalkTime != "Choose"
    }
    
    let subwayLines = ["Northern line", "Central line", "Jubilee line", "Victoria line"]
    let stations = [
        "Choose", "Woodside Park", "Waterloo", "Angel", "King's Cross", "Oxford Circus",
        "Piccadilly Circus", "Leicester Square", "Covent Garden", "Tottenham Court Road",
        "Bank", "London Bridge", "Canary Wharf", "Greenwich", "Stratford"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingHeader(
                step: 1,
                totalSteps: 4,
                title: "Where do you leave?"
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)
                    
                    // Your line dropdown
                    Dropdown(
                        label: "Your line",
                        items: subwayLines,
                        selectedItem: $selectedLine
                    )
                    .padding(.horizontal, 20)
                    
                    // Your station dropdown
                    Dropdown(
                        label: "Your station",
                        items: stations,
                        selectedItem: $selectedStation
                    )
                    .padding(.horizontal, 20)
                    
                    // How long do you walk to tube time picker
                    TimePicker(
                        label: "How long do you walk to tube?",
                        selectedValue: $selectedWalkTime
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
                    CustomButton(title: "Next", style: .filled, isEnabled: isFormValid) {
                        onNext()
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
    struct PreviewWrapper: View {
        @State private var selectedLine = "Northern line"
        @State private var selectedStation = "Choose"
        @State private var selectedWalkTime = "Choose"
        
        var body: some View {
            Onboarding1View(
                selectedLine: $selectedLine,
                selectedStation: $selectedStation,
                selectedWalkTime: $selectedWalkTime,
                onNext: { print("Next tapped") }
            )
        }
    }
    
    return PreviewWrapper()
}
