import SwiftUI

/// Fades content in with a small rise, and straight out. Used for the intro text and the
/// contents of the setup cards. Without the rise under Reduce Motion.
struct TextReveal: ViewModifier {
    var shown: Bool
    var delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Long, soft landing: moves quickly at first, then settles.
    static let enter = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.8)
    static let exit = Animation.easeOut(duration: 0.2)

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 10)
            .animation(shown ? Self.enter.delay(delay) : Self.exit, value: shown)
    }
}

extension View {
    func textReveal(_ shown: Bool, delay: Double) -> some View {
        modifier(TextReveal(shown: shown, delay: delay))
    }

    /// Reveals a setup card element once its step appears, `order` places after the first.
    func setupReveal(order: Int) -> some View {
        modifier(SetupReveal(order: order))
    }
}

private struct SetupReveal: ViewModifier {
    var order: Int

    @Environment(\.setupRevealed) private var revealed

    func body(content: Content) -> some View {
        content.textReveal(revealed, delay: 0.15 + 0.12 * Double(order))
    }
}

/// Slides an illustration in from the side with a fade, as the intro does between pages.
/// Fade only under Reduce Motion.
private struct ArtworkReveal: ViewModifier {
    var shown: Bool

    @Environment(\.setupArtworkFrom) private var from
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let visible = shown || from == nil
        content
            .opacity(visible ? 1 : 0)
            .offset(x: visible || reduceMotion ? 0 : from ?? 0)
            .animation(
                visible ? .timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(0.1) : TextReveal.exit,
                value: visible
            )
    }
}

extension View {
    /// Brings a setup illustration in once its screen appears (see `setupArtworkFrom`).
    func artworkReveal(_ shown: Bool) -> some View {
        modifier(ArtworkReveal(shown: shown))
    }
}

private struct SetupArtworkFromKey: EnvironmentKey {
    static let defaultValue: CGFloat? = 40
}

extension EnvironmentValues {
    /// Where a setup illustration slides in from: 40 from the right going forward, -40 from
    /// the left going back. nil when it arrives another way (the Back home card's move).
    var setupArtworkFrom: CGFloat? {
        get { self[SetupArtworkFromKey.self] }
        set { self[SetupArtworkFromKey.self] = newValue }
    }
}

private struct SetupRevealedKey: EnvironmentKey {
    /// Shown by default, so elements outside a setup step never stay hidden.
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Set by `SetupStepLayout`: false until the step has appeared.
    var setupRevealed: Bool {
        get { self[SetupRevealedKey.self] }
        set { self[SetupRevealedKey.self] = newValue }
    }
}
