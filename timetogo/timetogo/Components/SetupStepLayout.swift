import SwiftUI

/// Template for a setup step (Figma "Setup - Step 1"): step counter and title, the illustration
/// resting on a white card, the fields at the top of the card and the button at its bottom.
/// The illustration fills the width and only shrinks when the phone is too short for it;
/// the card takes the height that's left. Fields inside are outlined.
struct SetupStepLayout<Artwork: View, Fields: View>: View {
    var step: Int
    var totalSteps: Int = 3
    var title: String
    var showsBackButton: Bool = false
    var onBack: (() -> Void)? = nil
    var buttonTitle: String = "Next"
    var isButtonEnabled: Bool = true
    var onButton: () -> Void
    /// Between the fields. Figma: 24, or 48 above step 3's day row.
    var fieldSpacing: CGFloat = 24
    @ViewBuilder var artwork: () -> Artwork
    @ViewBuilder var fields: () -> Fields

    /// The card's elements fade in once the step appears (see `setupReveal`).
    @State private var revealed = false
    @Environment(\.setupMorph) private var morphNamespace

    /// Figma: the illustration frame.
    private let artworkSize = CGSize(width: 402, height: 263)

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                SetupHeader(
                    step: step,
                    totalSteps: totalSteps,
                    title: title,
                    showsBackButton: showsBackButton,
                    onBack: onBack
                )
                .padding(.horizontal, 29)
                // Arriving from the Back home card, the title fades in like the fields.
                .textReveal(morphNamespace == nil || revealed, delay: 0.05)
                // Figma: the step counter starts 67pt from the screen top.
                .padding(.top, max(67 - geo.safeAreaInsets.top, 12))
                .layoutPriority(2)

                artwork()
                    .aspectRatio(artworkSize, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .setupMorph("artwork")
                    .artworkReveal(revealed)
                    .padding(.top, 20)
                    .layoutPriority(1)

                card
                    .padding(.horizontal, Spacing.padding)
                    .padding(.bottom, Spacing.padding)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .background(Color.brightBackground.ignoresSafeArea())
        .environment(\.setupRevealed, revealed)
        .onAppear { revealed = true }
    }

    private var card: some View {
        SetupCard {
            VStack(alignment: .leading, spacing: fieldSpacing) {
                fields()
            }
            .environment(\.formFieldOutlined, true)

            Spacer(minLength: 24)

            CustomButton(title: buttonTitle, style: .filled, action: onButton, isEnabled: isButtonEnabled)
                .setupMorph("button")
        }
    }
}

/// White card used by the setup screens. Fills the height it's given.
struct SetupCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .padding(Spacing.paddingInside)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // On the shape, not the card: a shadow on the card also lands on its text.
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 4.5)
                    .setupMorph("card")
            )
    }
}

// MARK: - Changing steps

extension View {
    /// For each step in a setup flow: the incoming step is drawn whole on top while the
    /// outgoing one fades beneath it, so only the new step's own animations show.
    /// `layer` must rise with every step change.
    func setupStepTransition(layer: Double) -> some View {
        transition(.asymmetric(insertion: .identity, removal: .opacity))
            .zIndex(layer)
    }
}

// MARK: - Morph into setup

private struct SetupMorphKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    /// When set, the artwork, card and button move between screens sharing it
    /// (Back home card into Back home setup) instead of fading.
    var setupMorph: Namespace.ID? {
        get { self[SetupMorphKey.self] }
        set { self[SetupMorphKey.self] = newValue }
    }
}

extension View {
    func setupMorph(_ id: String) -> some View {
        modifier(SetupMorph(id: id))
    }
}

private struct SetupMorph: ViewModifier {
    var id: String
    @Environment(\.setupMorph) private var namespace

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedGeometryEffect(id: id, in: namespace)
        } else {
            content
        }
    }
}
