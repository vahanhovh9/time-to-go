//
//  Colors.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    static let white = Color(hex: "FFFFFF")
    static let grey10 = Color(hex: "EBEBEB")
    static let grey30 = Color(hex: "949494")
    static let grey50 = Color(hex: "3E3E3E")
    static let black = Color(hex: "000000")
    static let yellow = Color(hex: "FFF9E6") // Light yellow background
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}









// MARK: - TfL line colours

extension Color {
    /// TfL's colour for a line ID ("northern", "elizabeth", "mildmay", …); grey when unknown,
    /// e.g. National Rail operators like Thameslink.
    static func tflLine(_ id: String?) -> Color {
        switch id ?? "" {
        case "bakerloo":         return Color(hex: "B36305")
        case "central":          return Color(hex: "E32017")
        case "circle":           return Color(hex: "FFD300")
        case "district":         return Color(hex: "00782A")
        case "hammersmith-city": return Color(hex: "F3A9BB")
        case "jubilee":          return Color(hex: "A0A5A9")
        case "metropolitan":     return Color(hex: "9B0056")
        case "northern":         return Color(hex: "000000")
        case "piccadilly":       return Color(hex: "003688")
        case "victoria":         return Color(hex: "0098D4")
        case "waterloo-city":    return Color(hex: "95CDBA")
        case "elizabeth":        return Color(hex: "6950A1")
        case "dlr":              return Color(hex: "00A4A7")
        case "liberty":          return Color(hex: "61686B")
        case "lioness":          return Color(hex: "FAA61A")
        case "mildmay":          return Color(hex: "437EC1")
        case "suffragette":      return Color(hex: "39B97A")
        case "weaver":           return Color(hex: "972861")
        case "windrush":         return Color(hex: "EF4D5E")
        default:                 return .grey50
        }
    }
}
