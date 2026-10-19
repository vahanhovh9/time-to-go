//
//  TextStyles.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

// MARK: - Figma text styles (Timetogo file, "Final/…")

/// Text styles from the Figma file. Apply with `.typography(.h2)`.
/// Sizes are the design sizes at the default text size; they grow and shrink with the
/// user's text size setting (Settings → Display → Text Size).
enum AppTextStyle: CaseIterable {
    /// 40 Bold, -2 — big page titles ("Settings"). Figma: Old/H1.
    case display
    /// 28 Bold, -0.5 — onboarding step titles ("Where do you leave?"). Figma: Final/H1.
    case h1
    /// 24 Bold, -0.5 — journey and group titles, destination cards. Figma: Final/H2.
    case h2
    /// 18 Bold, -0.5 — field values, card titles. Figma: Final/H3.
    case h3
    /// 16 Semibold — step counter ("01 / 3"), station names. Figma: Final/H4.
    case h4
    /// 15 Semibold. Figma: H5.
    case h5
    /// 20 Bold, -0.5 — button labels. Figma: Old/H3.
    case button
    /// 16 Medium, -0.5, 140% line height — body copy, settings rows, departures. Figma: Final/Large.
    case large
    /// 14 Medium, -0.5 — field labels, "LEAVE TODAY AT". Figma: Final/Main.
    case main
    /// 13 Regular — line status, minutes chips. Figma: Final/Small.
    case small
    /// 11 Regular — secondary lines. Figma: Final/Footnote.
    case footnote

    var size: CGFloat {
        switch self {
        case .display:  return 40
        case .h1:       return 28
        case .h2:       return 24
        case .h3:       return 18
        case .h4:       return 16
        case .h5:       return 15
        case .button:   return 20
        case .large:    return 16
        case .main:     return 14
        case .small:    return 13
        case .footnote: return 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .h1, .h2, .h3, .button: return .bold
        case .h4, .h5:                         return .semibold
        case .large, .main:                    return .medium
        case .small, .footnote:                return .regular
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display:                                return -2
        case .h1, .h2, .h3, .button, .large, .main:   return -0.5
        case .h4, .h5, .small, .footnote:             return 0
        }
    }

    /// Line height as a multiple of the font size; nil = the font's natural line height.
    var lineHeight: CGFloat? {
        self == .large ? 1.4 : nil
    }
}

extension View {
    func typography(_ style: AppTextStyle) -> some View {
        modifier(ScaledFont(size: style.size, weight: style.weight, design: .default, lineHeight: style.lineHeight))
            .tracking(style.tracking)
    }

    /// System font at a design size that follows the user's text size setting.
    /// Use for one-off sizes; prefer `typography(_:)` where a Figma style fits.
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design, lineHeight: nil))
    }
}

// MARK: - Dynamic Type

private struct ScaledFont: ViewModifier {
    let weight: Font.Weight
    let design: Font.Design
    let lineHeight: CGFloat?
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, lineHeight: CGFloat?) {
        self.weight = weight
        self.design = design
        self.lineHeight = lineHeight
        _size = ScaledMetric(wrappedValue: size, relativeTo: Self.textStyle(for: size))
    }

    func body(content: Content) -> some View {
        // Figma line height: every line is `size × lineHeight` tall, so the extra space
        // goes between lines and, split in half, above the first and below the last.
        let extra = lineHeight.map { max(0, size * $0 - naturalLineHeight) } ?? 0
        content
            .font(.system(size: size, weight: weight, design: design))
            .lineSpacing(extra)
            .padding(.vertical, extra / 2)
    }

    private var naturalLineHeight: CGFloat {
        UIFont.systemFont(ofSize: size, weight: Self.uiWeight(weight)).lineHeight
    }

    private static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .regular
        }
    }

    /// The iOS text style whose scaling curve suits this size: big display text grows
    /// gently, small text grows the most.
    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 34...: return .largeTitle
        case 24...: return .title2
        case 20...: return .title3
        case 17...: return .body
        case 15...: return .subheadline
        case 13...: return .footnote
        case 12...: return .caption
        default:    return .caption2
        }
    }
}
