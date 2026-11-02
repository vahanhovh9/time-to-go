import SwiftUI

/// Back home tab before outbound is set up (Figma "BH - onboarding").
struct OutboundEmptyView: View {
    var onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            // Scales to the available height, so the figure is never cut off on small phones.
            JourneyIllustration(journey: .walkingHome)
                .aspectRatio(CGSize(width: 402, height: 263), contentMode: .fit)

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
            }
            .frame(maxHeight: 325)
            .layoutPriority(1)
            .padding(.horizontal, 20)
            // Figma: 35pt above the tab bar.
            .padding(.bottom, 35)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brightBackground.ignoresSafeArea())
    }
}

#Preview {
    OutboundEmptyView(onGetStarted: {})
}
