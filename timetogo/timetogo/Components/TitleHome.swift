//
//  TitleHome.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct TitleHome: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .h1Style()
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(subtitle)
                .bodyTextStyle()
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    TitleHome(
        title: "Time to GO!",
        subtitle: "A simple vibe coded app designed to help you ARRIVING ON TIME"
    )
    .padding()
    .background(Color.white)
}


