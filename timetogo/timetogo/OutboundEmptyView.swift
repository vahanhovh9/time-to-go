import SwiftUI

/// Back home tab before outbound is set up (Figma "BH - onboarding").
struct OutboundEmptyView: View {
    var onGetStarted: () -> Void

    var body: some View {
        GeometryReader { geo in
            content(topInset: geo.safeAreaInsets.top)
        }
        .background(Color.brightBackground.ignoresSafeArea())
    }

    private func content(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Setup's header, unseen, so the illustration sits exactly where "Where are you
            // heading?" has it and stays put on Let's go. Same spacing as SetupStepLayout.
            SetupHeader(step: 1, totalSteps: 2, title: "Where are you heading?", showsBackButton: true)
                .padding(.horizontal, 29)
                .padding(.top, max(67 - topInset, 12))
                .hidden()
                .accessibilityHidden(true)
                .layoutPriority(2)

            // Scales to the available height, so the figure is never cut off on small phones.
            JourneyIllustration(journey: .walkingHome)
                .aspectRatio(CGSize(width: 402, height: 263), contentMode: .fit)
                .frame(maxWidth: .infinity)
                .setupMorph("artwork")
                .padding(.top, 20)

            Spacer(minLength: 8)

            SetupCard {
                VStack(spacing: 12) {
                    Text("Need to be back right on time?")
                        .typography(.h2)
                        .foregroundColor(.black)
                    Text("Use Back home to know when you should leave the office.")
                        .typography(.large)
                        .foregroundColor(.grey40)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 24)

                CustomButton(title: "Let’s go", style: .filled, action: onGetStarted)
                    .setupMorph("button")
            }
            .frame(maxHeight: 325)
            .layoutPriority(1)
            .padding(.horizontal, Spacing.padding)
            // Figma: 35pt above the tab bar.
            .padding(.bottom, 35)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OutboundEmptyView(onGetStarted: {})
}
