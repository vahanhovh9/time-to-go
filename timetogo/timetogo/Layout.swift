import SwiftUI

// MARK: - Corner radius (Figma variables)

enum Radius {
    /// Tags inside cards: the journey page's line badge and delay pill. Figma: Extra small.
    static let extraSmall: CGFloat = 8
    /// The leave-time card's line-status pill and the success page's next-commute block.
    /// Figma: Small element.
    static let smallElement: CGFloat = 14
    /// Buttons, fields, day chips, destination cards, minutes chips and the journey page's
    /// train cards. Figma: Element.
    static let element: CGFloat = 18
    /// Leave-time card, departures card and Settings cards. Figma: Small block.
    static let smallBlock: CGFloat = 22
    /// Figma: Corner/Medium. Not in use at the moment.
    static let medium: CGFloat = 12
    /// Large white cards: intro, setup steps, success, Back home. Figma: 36 (no variable yet).
    static let card: CGFloat = 36
    /// Top corners of the journey sheet. Figma: 38 (no variable yet).
    static let sheet: CGFloat = 38
}

// MARK: - Spacing (Figma variables)

enum Spacing {
    /// From the screen edges to the large cards. Figma: Padding.
    static let padding: CGFloat = 20
    /// Inside the large cards. Figma: Padding inside.
    static let paddingInside: CGFloat = 24
}
