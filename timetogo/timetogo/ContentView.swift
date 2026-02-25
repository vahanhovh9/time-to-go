//
//  ContentView.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

enum OnboardingStep {
    case step1
    case step2
    case step3
    case step4
    case success
}

struct ContentView: View {
    @State private var showDesignSystem = false
    @State private var showMain = false
    @State private var currentOnboardingStep: OnboardingStep = .step1
    
    // Onboarding state (prefilled when returning to settings)
    @State private var homeLine = "Northern line"
    @State private var homeStation = "Choose"
    @State private var homeWalkTime = "Choose"
    @State private var officeLine = "Northern line"
    @State private var officeStation = "Choose"
    @State private var officeWalkTime = "Choose"
    @State private var arrivalTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var monday = false
    @State private var tuesday = true
    @State private var wednesday = false
    @State private var thursday = true
    @State private var friday = false
    @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if showDesignSystem {
                DesignSystemView()
            } else if showMain {
                MainView(onChangeSettings: {
                    withAnimation {
                        showMain = false
                        currentOnboardingStep = .step1
                    }
                })
            } else {
                onboardingView
            }
            
            // Switcher button
            Button {
                withAnimation {
                    showDesignSystem.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showDesignSystem ? "app.fill" : "paintpalette.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text(showDesignSystem ? "App" : "Design System")
                        .labelStyle()
                }
                .foregroundColor(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
            .zIndex(1000)
        }
    }
    
    @ViewBuilder
    private var onboardingView: some View {
        switch currentOnboardingStep {
        case .step1:
            Onboarding1View(
                selectedLine: $homeLine,
                selectedStation: $homeStation,
                selectedWalkTime: $homeWalkTime,
                onNext: {
                    withAnimation {
                        currentOnboardingStep = .step2
                    }
                }
            )
        case .step2:
            Onboarding2View(
                selectedLine: $officeLine,
                selectedStation: $officeStation,
                selectedWalkTime: $officeWalkTime,
                onNext: {
                    withAnimation {
                        currentOnboardingStep = .step3
                    }
                },
                onBack: {
                    withAnimation {
                        currentOnboardingStep = .step1
                    }
                }
            )
        case .step3:
            Onboarding3View(
                arrivalTime: $arrivalTime,
                monday: $monday,
                tuesday: $tuesday,
                wednesday: $wednesday,
                thursday: $thursday,
                friday: $friday,
                onNext: {
                    withAnimation {
                        currentOnboardingStep = .step4
                    }
                },
                onBack: {
                    withAnimation {
                        currentOnboardingStep = .step2
                    }
                }
            )
        case .step4:
            Onboarding4View(
                notificationTime: $notificationTime,
                onComplete: {
                    withAnimation {
                        currentOnboardingStep = .success
                    }
                },
                onBack: {
                    withAnimation {
                        currentOnboardingStep = .step3
                    }
                }
            )
        case .success:
            OnboardingSuccessView(
                onAllDone: {
                    withAnimation {
                        showMain = true
                    }
                },
                onChangeSettings: {
                    // Navigate back to step 1 to change settings
                    withAnimation {
                        showMain = false
                        currentOnboardingStep = .step1
                    }
                }
            )
        }
    }
}

#Preview {
    ContentView()
}
