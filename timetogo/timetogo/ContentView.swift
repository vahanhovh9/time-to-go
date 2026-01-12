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
    @State private var currentOnboardingStep: OnboardingStep = .step1
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if showDesignSystem {
                DesignSystemView()
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
                onNext: {
                    withAnimation {
                        currentOnboardingStep = .step2
                    }
                }
            )
        case .step2:
            Onboarding2View(
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
                    // Handle completion - could navigate to main app
                    print("All done tapped")
                },
                onChangeSettings: {
                    // Navigate back to step 1 to change settings
                    withAnimation {
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
