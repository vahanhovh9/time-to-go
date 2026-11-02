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
    /// Extra space above the fields, for a first row without a label.
    var fieldsTopInset: CGFloat = 0
    @ViewBuilder var artwork: () -> Artwork
    @ViewBuilder var fields: () -> Fields

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
                // Figma: the step counter starts 67pt from the screen top.
                .padding(.top, max(67 - geo.safeAreaInsets.top, 12))
                .layoutPriority(2)

                artwork()
                    .aspectRatio(artworkSize, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .layoutPriority(1)

                card
                    .padding(.horizontal, 20)
                    // Figma: 30pt from the screen bottom.
                    .padding(.bottom, max(geo.safeAreaInsets.bottom - 4, 16))
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .background(Color.brightBackground.ignoresSafeArea())
    }

    private var card: some View {
        SetupCard {
            VStack(alignment: .leading, spacing: 32) {
                fields()
            }
            .padding(.top, fieldsTopInset)
            .environment(\.formFieldOutlined, true)

            Spacer(minLength: 24)

            CustomButton(title: buttonTitle, style: .filled, action: onButton, isEnabled: isButtonEnabled)
        }
    }
}

/// White card used by the setup screens. Fills the height it's given.
struct SetupCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // On the shape, not the card: a shadow on the card also lands on its text.
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 4.5)
            )
    }
}
