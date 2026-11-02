import SwiftUI

// MARK: - Corner radius (Figma variables)

enum Radius {
    /// Buttons, fields, day chips, destination cards and small pills. Figma: Element.
    static let element: CGFloat = 18
    /// Leave-time card, departures card, Settings cards and the success page's
    /// next-commute block. Figma: Small block.
    static let smallBlock: CGFloat = 22
    /// Figma: Corner/Medium. Not in use at the moment.
    static let medium: CGFloat = 12
    /// Large white cards: intro, setup steps, success, Back home. Figma: 36 (no variable yet).
    static let card: CGFloat = 36
}

// MARK: - Spacing (Figma variables)

enum Spacing {
    /// From the screen edges to the large cards. Figma: Padding.
    static let padding: CGFloat = 20
    /// Inside the large cards. Figma: Padding inside.
    static let paddingInside: CGFloat = 24
}
