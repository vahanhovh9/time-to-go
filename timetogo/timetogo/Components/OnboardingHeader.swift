//
//  OnboardingHeader.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct OnboardingHeader: View {
    var step: Int?
    var totalSteps: Int?
    var title: String
    var showsBackButton: Bool = false
    var onBack: (() -> Void)? = nil
    
    private var progressText: String? {
        guard let step = step else { return nil }
        guard let totalSteps = totalSteps, totalSteps > 0 else {
            return String(format: "%02d", step)
        }
        return String(format: "%02d / %d", step, totalSteps)
    }
    
    var body: some View {
        if let progressText {
            // Figma "Onboarding - Step" header: step counter row, then a 24pt title.
            VStack(alignment: .leading, spacing: 12) {
                progressRow(progressText)
                Text(title)
                    .typography(.title)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Success screens: centred large title under the black bar.
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
                Text(title)
                    .h1Style()
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 88, alignment: .top)
        }
    }

    @ViewBuilder
    private func progressRow(_ text: String) -> some View {
        let label = Text(text)
            .typography(.h4)
            .foregroundColor(.grey30)

        if showsBackButton {
            Button { onBack?() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.grey30)
                    label
                }
                .frame(height: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back, step \(text)")
        } else {
            label.frame(height: 24)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 32) {
        OnboardingHeader(step: 1, totalSteps: 4, title: "Where do you live?")
        OnboardingHeader(step: 2, totalSteps: 4, title: "Where do you live?", showsBackButton: true) {}
        OnboardingHeader(step: nil, totalSteps: nil, title: "Awesome all set up!")
    }
    .padding()
    .background(Color.white)
}


