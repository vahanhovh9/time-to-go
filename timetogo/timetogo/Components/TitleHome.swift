//
//  TitleHome.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 31/10/2025.
//

import SwiftUI

struct TitleHome: View {
    var title: String
    var subtitle: String? = nil
    var alignment: HorizontalAlignment = .leading
    var textAlignment: TextAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 24) {
            Text(title)
                .h1Style()
                .foregroundColor(Color.black)
                .multilineTextAlignment(textAlignment)
                .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
            
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .bodyTextStyle()
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(textAlignment)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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


