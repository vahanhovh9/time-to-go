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
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black)
                .frame(height: 4)
                .frame(maxWidth: .infinity)
            
            contentStack
                .frame(maxWidth: .infinity)
                .frame(height: contentHeight)
        }
        .frame(height: totalHeight, alignment: .top)
    }
    
    @ViewBuilder
    private var headerContent: some View {
        if let progressText = progressText {
            if showsBackButton {
                Button {
                    onBack?()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.grey30)
                            .frame(width: 25, height: 25, alignment: .center)
                        
                        Text(progressText)
                            .labelStyle()
                            .foregroundColor(Color.grey30)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                Text(progressText)
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder
    private var contentStack: some View {
        if progressText != nil {
            VStack(alignment: .leading, spacing: 4) {
                headerContent
                
                Text(title)
                    .h2Style()
                    .foregroundColor(Color.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .bottom)
        } else {
            Text(title)
                .h2Style()
                .foregroundColor(Color.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    private var isVariantWithProgress: Bool {
        progressText != nil
    }
    
    private var totalHeight: CGFloat {
        isVariantWithProgress ? 88 : 72
    }
    
    private var contentHeight: CGFloat {
        isVariantWithProgress ? 84 : 68
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


