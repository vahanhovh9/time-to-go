//
//  InfoCard.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct InfoItemData: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var time: String
    var iconColor: Color
    var iconName: String
}

struct InfoItem: View {
    var data: InfoItemData
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(data.iconColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    )
                
                Image(systemName: data.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.black)
            }
            
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(data.title)
                        .h4Style()
                        .foregroundColor(Color.black)
                    
                    Text(data.subtitle)
                        .labelStyle()
                        .foregroundColor(Color.grey30)
                }
                
                Spacer()
                
                Text(data.time)
                    .h4Style()
                    .foregroundColor(Color.black)
            }
        }
        .frame(height: 40)
    }
}

struct InfoCard: View {
    var items: [InfoItemData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(items) { item in
                InfoItem(data: item)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(width: 353, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
    }
}

#Preview {
    InfoCard(
        items: [
            InfoItemData(title: "Home", subtitle: "Woodside Park", time: "08:24", iconColor: Color(red: 1.0, green: 0.689, blue: 0.689), iconName: "house.fill"),
            InfoItemData(title: "Work", subtitle: "Waterloo", time: "08:24", iconColor: Color(red: 0.973, green: 0.925, blue: 0.51), iconName: "tram.fill"),
            InfoItemData(title: "Gym", subtitle: "Angel", time: "08:24", iconColor: Color(red: 0.64, green: 0.986, blue: 0.515), iconName: "figure.run")
        ]
    )
    .padding()
    .background(Color.white)
}


