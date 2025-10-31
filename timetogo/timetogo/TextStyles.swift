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
            .tracking(-1)
            .lineSpacing(20.4 - 17) // 120% line height = 20.4px
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
