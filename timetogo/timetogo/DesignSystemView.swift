//
//  DesignSystemView.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

struct DesignSystemView: View {
    @State private var selectedLine = "Northern line"
    @State private var monday = false
    @State private var tuesday = false
    @State private var wednesday = false
    @State private var thursday = false
    @State private var friday = false
    
    let subwayLines = ["Northern line", "Central line", "Jubilee line", "Victoria line"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Title
                Text("Design System Showcase")
                    .h1Style()
                    .foregroundColor(Color.black)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Typography Section
                typographySection
                
                // Colors Section
                colorsSection
                
                // Components Section
                componentsSection
                
                Spacer(minLength: 40)
            }
            .padding(.bottom, 40)
        }
        .background(Color.white)
    }
    
    // MARK: - Typography Section
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Typography")
                .h2Style()
                .foregroundColor(Color.black)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 32) {
                Text("Time")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("12:30 PM")
                    .timeStyle()
                    .foregroundColor(Color.black)
                
                Text("80px, -4p, 100%")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("H1")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("Heading 1")
                    .h1Style()
                    .foregroundColor(Color.black)
                
                Text("40px, -2p, 100%")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("H2")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("Heading 2")
                    .h2Style()
                    .foregroundColor(Color.black)
                
                Text("24px, -1px, 100%")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("H3")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("Heading 3")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                Text("20px, -0.5px")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("H4")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("Heading 4")
                    .h4Style()
                    .foregroundColor(Color.black)
                
                Text("17px, -0.5px, 120%")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Body Text")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("This is body text with longer content for display purposes.")
                    .bodyTextStyle()
                    .foregroundColor(Color.black)
                
                Text("20px, -1px, 123%")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Label")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("Label text")
                    .labelStyle()
                    .foregroundColor(Color.black)
                
                Text("16px, -0.5px")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Body Small")
                    .labelStyle()
                    .foregroundColor(Color.grey30)
                
                Text("Small body text for additional information.")
                    .bodySmallStyle()
                    .foregroundColor(Color.black)
                
                Text("14px, 0px, 120%")
                    .bodySmallStyle()
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Colors Section
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Color Palette")
                .h2Style()
                .foregroundColor(Color.black)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                ColorCard(name: "White", hex: "#FFFFFF", color: Color.white, textColor: Color.black)
                ColorCard(name: "Grey 10", hex: "#EBEBEB", color: Color.grey10, textColor: Color.black)
                ColorCard(name: "Grey 30", hex: "#949494", color: Color.grey30, textColor: Color.white)
                ColorCard(name: "Grey 50", hex: "#3E3E3E", color: Color.grey50, textColor: Color.white)
                ColorCard(name: "Black", hex: "#000000", color: Color.black, textColor: Color.white)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Components Section
    private var componentsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Components")
                .h2Style()
                .foregroundColor(Color.black)
                .padding(.horizontal)
            
            // Title Home
            VStack(alignment: .leading, spacing: 16) {
                Text("Title Home")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                TitleHome(
                    title: "Time to GO!",
                    subtitle: "A simple vibe coded app designed to help you ARRIVING ON TIME"
                )
            }
            .padding(.horizontal)
            
            // Onboarding Header
            VStack(alignment: .leading, spacing: 16) {
                Text("Onboarding Header")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                VStack(alignment: .leading, spacing: 24) {
                    OnboardingHeader(step: 1, totalSteps: 4, title: "Where do you live?")
                    OnboardingHeader(step: 2, totalSteps: 4, title: "Where do you live?", showsBackButton: true) {
                        print("Back tapped")
                    }
                    OnboardingHeader(step: nil, totalSteps: nil, title: "Awesome all set up!")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.grey10)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // Time Display
            VStack(alignment: .leading, spacing: 16) {
                Text("Time Display")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                TimeDisplay(time: "12:59 AM")
            }
            .padding(.horizontal)
            
            // Info Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Info")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                InfoCard(
                    items: [
                        InfoItemData(title: "Home", subtitle: "Woodside Park", time: "08:24", iconColor: Color(red: 1.0, green: 0.689, blue: 0.689), iconName: "house.fill"),
                        InfoItemData(title: "Work", subtitle: "Waterloo", time: "08:24", iconColor: Color(red: 0.973, green: 0.925, blue: 0.51), iconName: "tram.fill"),
                        InfoItemData(title: "Gym", subtitle: "Angel", time: "08:24", iconColor: Color(red: 0.64, green: 0.986, blue: 0.515), iconName: "figure.run")
                    ]
                )
            }
            .padding(.horizontal)
            
            // Checkmark
            VStack(alignment: .leading, spacing: 16) {
                Text("Checkmark")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Checkmark(state: .unchecked)
                        Text("Unchecked")
                            .bodySmallStyle()
                            .foregroundColor(Color.grey50)
                    }
                    
                    VStack(spacing: 8) {
                        Checkmark(state: .checked)
                        Text("Checked")
                            .bodySmallStyle()
                            .foregroundColor(Color.grey50)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.grey10)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // Dropdown
            VStack(alignment: .leading, spacing: 16) {
                Text("Dropdown")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                Dropdown(
                    label: "Your line",
                    items: subwayLines,
                    selectedItem: $selectedLine
                )
            }
            .padding(.horizontal)
            
            // Buttons
            VStack(alignment: .leading, spacing: 16) {
                Text("Button")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                VStack(spacing: 12) {
                    CustomButton(title: "Next", style: .filled) {
                        print("Next tapped")
                    }
                    
                    CustomButton(title: "Change you settings", style: .outline) {
                        print("Settings tapped")
                    }
                }
            }
            .padding(.horizontal)
            
            // Day Picker
            VStack(alignment: .leading, spacing: 16) {
                Text("Day Picker")
                    .h3Style()
                    .foregroundColor(Color.black)
                
                VStack(spacing: 12) {
                    DayPicker(day: "Monday", isSelected: $monday)
                    DayPicker(day: "Tuesday", isSelected: $tuesday)
                    DayPicker(day: "Wednesday", isSelected: $wednesday)
                    DayPicker(day: "Thursday", isSelected: $thursday)
                    DayPicker(day: "Friday", isSelected: $friday)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ColorCard: View {
    let name: String
    let hex: String
    let color: Color
    let textColor: Color
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(color)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .h4Style()
                    .foregroundColor(textColor)
                
                Text(hex)
                    .labelStyle()
                    .foregroundColor(textColor.opacity(0.8))
            }
            .padding(.leading, 20)
            
            Spacer()
        }
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    DesignSystemView()
}
