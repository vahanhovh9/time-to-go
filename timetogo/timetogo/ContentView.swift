//
//  ContentView.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showDesignSystem = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if showDesignSystem {
                DesignSystemView()
            } else {
                Onboarding1View()
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
}

#Preview {
    ContentView()
}
