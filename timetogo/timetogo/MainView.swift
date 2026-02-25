//
//  MainView.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct MainView: View {
    var onChangeSettings: () -> Void
    
    private let infoItems: [InfoItemData] = [
        InfoItemData(title: "Home", subtitle: "Woodside Park", time: "08:24", iconColor: Color(red: 1.0, green: 0.689, blue: 0.689), iconName: "house.fill"),
        InfoItemData(title: "Tube Journey", subtitle: "17 stations", time: "33 min", iconColor: Color(red: 0.973, green: 0.925, blue: 0.51), iconName: "tram.fill"),
        InfoItemData(title: "Work", subtitle: "Old Street", time: "09:00", iconColor: Color(red: 0.64, green: 0.986, blue: 0.515), iconName: "building.2.fill")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 32) {
                OnboardingHeader(
                    step: nil,
                    totalSteps: nil,
                    title: "Leave home at"
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                TimeDisplay(day: "Today at", time: "8:19 AM")
                    .padding(.horizontal, 20)
                
                Text("Good service on all lines")
                    .bodySmallStyle()
                    .foregroundColor(Color.black)
                
                InfoCard(items: infoItems)
                    .padding(.horizontal, 20)
                
                CustomButton(title: "Change your settings", style: .outline) {
                    onChangeSettings()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding(.bottom, 40)
        }
        .background(
            ZStack {
                Color.yellow
                Image("bg-main")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        )
    }
}

#Preview {
    MainView(onChangeSettings: { print("Change settings tapped") })
}
