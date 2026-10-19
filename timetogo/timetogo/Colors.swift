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
    /// Secondary text on grey surfaces (e.g. the journey page's train cards).
    static let grey40 = Color(hex: "686868")
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









// MARK: - Line colours

extension Color {
    /// Colour for a journey line ID: TfL's line colours ("northern", "elizabeth", "mildmay", …)
    /// and the main National Rail operators' brand colours ("thameslink", "southern", …).
    /// Grey when unknown.
    static func tflLine(_ id: String?) -> Color {
        Color(hex: lineHex(id))
    }

    /// Black or white, whichever reads better on `tflLine(id)` (higher WCAG contrast).
    /// Lines in `whiteTextLines` always get white, matching TfL's own badges.
    static func tflLineText(_ id: String?) -> Color {
        if let id, whiteTextLines.contains(id) { return .white }
        let hex = lineHex(id)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        func channel(_ shift: UInt64) -> Double {
            let c = Double((value >> shift) & 0xFF) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
        let onWhite = 1.05 / (luminance + 0.05)
        let onBlack = (luminance + 0.05) / 0.05
        return onWhite >= onBlack ? .white : .black
    }

    /// Mid-tone lines where contrast alone would pick black text.
    private static let whiteTextLines: Set<String> = ["victoria", "bakerloo"]

    private static func lineHex(_ id: String?) -> String {
        switch id ?? "" {
        // Tube
        case "bakerloo":         return "B36305"
        case "central":          return "E32017"
        case "circle":           return "FFD300"
        case "district":         return "00782A"
        case "hammersmith-city": return "F3A9BB"
        case "jubilee":          return "A0A5A9"
        case "metropolitan":     return "9B0056"
        case "northern":         return "000000"
        case "piccadilly":       return "003688"
        case "victoria":         return "0098D4"
        case "waterloo-city":    return "95CDBA"
        // Elizabeth line, DLR, Overground
        case "elizabeth":        return "6950A1"
        case "dlr":              return "00A4A7"
        case "liberty":          return "61686B"
        case "lioness":          return "FAA61A"
        case "mildmay":          return "437EC1"
        case "suffragette":      return "39B97A"
        case "weaver":           return "972861"
        case "windrush":         return "EF4D5E"
        // National Rail operators serving London
        case "thameslink":                    return "E9438D"
        case "southern":                      return "8CC63E"
        case "southeastern":                  return "389CFF"
        case "great-northern":                return "0099FF"
        case "c2c":                           return "B7007C"
        case "greater-anglia":                return "D70428"
        case "south-western-railway":         return "24398C"
        case "chiltern-railways":             return "00BFFF"
        case "great-western-railway":         return "0A493E"
        case "gatwick-express":               return "EB1E2D"
        case "heathrow-express":              return "532E63"
        case "west-midlands-trains":          return "FF8300"
        case "avanti-west-coast":             return "004354"
        case "london-north-eastern-railway":  return "CE0E2D"
        case "east-midlands-railway":         return "713563"
        default:                              return "3E3E3E"   // Grey 50
        }
    }
}
