//
//  TextStyles.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

// MARK: - Typography Styles
struct Typography {
    // MARK: - Time
    static func time() -> Font {
        return .system(size: 80, weight: .bold)
    }
    
    // MARK: - Headings
    static func h1() -> Font {
        return .system(size: 40, weight: .bold)
    }
    
    static func h2() -> Font {
        return .system(size: 24, weight: .bold)
    }
    
    static func h3() -> Font {
        return .system(size: 20, weight: .bold)
    }
    
    static func h4() -> Font {
        return .system(size: 17, weight: .bold)
    }
    
    // MARK: - Body Text
    static func bodyText() -> Font {
        return .system(size: 20, weight: .medium)
    }
    
    static func label() -> Font {
        return .system(size: 16, weight: .medium)
    }
    
    static func bodySmall() -> Font {
        return .system(size: 14, weight: .medium)
    }
}

// MARK: - View Modifier for Typography with Line Height
extension View {
    func timeStyle() -> some View {
        self.modifier(TimeStyle())
    }
    
    func h1Style() -> some View {
        self.modifier(H1Style())
    }
    
    func h2Style() -> some View {
        self.modifier(H2Style())
    }
    
    func h3Style() -> some View {
        self.modifier(H3Style())
    }
    
    func h4Style() -> some View {
        self.modifier(H4Style())
    }
    
    func bodyTextStyle() -> some View {
        self.modifier(BodyTextStyle())
    }
    
    func labelStyle() -> some View {
        self.modifier(LabelStyle())
    }
    
    func bodySmallStyle() -> some View {
        self.modifier(BodySmallStyle())
    }
}

// MARK: - Typography Modifiers
struct TimeStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.time())
            .tracking(-4)
            .lineSpacing(100 - 80) // 100% line height = 80px
    }
}

struct H1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.h1())
            .tracking(-2)
            .lineSpacing(100 - 40) // 100% line height = 40px
    }
}

struct H2Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.h2())
            .tracking(-1)
            .lineSpacing(100 - 24) // 100% line height = 24px
    }
}

struct H3Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.h3())
            .tracking(-0.5)
            .lineSpacing(20) // Assuming default line spacing
    }
}

struct H4Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.h4())
            .tracking(-0.5)
            .lineSpacing(20.4 - 17) // 120% line height = 20.4px
            .padding(.trailing, 1)
    }
}

struct BodyTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.bodyText())
            .tracking(-1)
            .lineSpacing(24.6 - 20) // 123% line height = 24.6px
    }
}

struct LabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.label())
            .tracking(-0.5)
    }
}

struct BodySmallStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.bodySmall())
            .tracking(0)
            .lineSpacing(16.8 - 14) // 120% line height = 16.8px
    }
}

// MARK: - Figma text styles (Timetogo file, "Final/…")

/// Text styles from the Figma file. Apply with `.typography(.title)`.
enum AppTextStyle {
    /// 40 Bold, -2 — big page titles ("Settings"). Figma: Old/H1.
    case display
    /// 24 Bold, -0.5 — onboarding step titles ("Where do you leave?").
    case title
    /// 20 Bold, -0.5 — section titles, primary button. Figma: Final/H2.
    case h2
    /// 16 Bold, -0.5 — field values, card titles. Figma: Final/H3.
    case h3
    /// 13 Semibold — step counter ("01 / 3"), small headings. Figma: Final/H4.
    case h4
    /// 14 Medium, -0.5 — list labels. Figma: Final/Large.
    case large
    /// 13 Medium, -0.5 — field labels, body. Figma: Final/Main.
    case main
    /// 12 Regular. Figma: Final/Small.
    case small
    /// 11 Regular — secondary lines. Figma: Final/Footnote.
    case footnote

    var font: Font {
        switch self {
        case .display:  return .system(size: 40, weight: .bold)
        case .title:    return .system(size: 24, weight: .bold)
        case .h2:       return .system(size: 20, weight: .bold)
        case .h3:       return .system(size: 16, weight: .bold)
        case .h4:       return .system(size: 13, weight: .semibold)
        case .large:    return .system(size: 14, weight: .medium)
        case .main:     return .system(size: 13, weight: .medium)
        case .small:    return .system(size: 12)
        case .footnote: return .system(size: 11)
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display:                        return -2
        case .title, .h2, .h3, .large, .main: return -0.5
        case .h4, .small, .footnote:          return 0
        }
    }
}

extension View {
    func typography(_ style: AppTextStyle) -> some View {
        font(style.font).tracking(style.tracking)
    }
}
