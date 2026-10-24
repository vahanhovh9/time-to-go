import SwiftUI

/// Back home tab before outbound is set up (Figma "BH - setup").
struct OutboundEmptyView: View {
    var onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            // Scales to the available height, so the figure is never cut off on small phones.
            JourneyIllustration(journey: .walkingHome)
                .frame(maxHeight: 302)

            Spacer(minLength: 24)

            VStack(spacing: 48) {
                VStack(spacing: 16) {
                    Text("Need to be back right on time?")
                        .typography(.h1)
                        .foregroundColor(.black)
                    Text("Use Back home to know when you should leave the office.")
                        .typography(.large)
                        .foregroundColor(.grey50)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

                CustomButton(title: "Let’s go", style: .filled, action: onGetStarted)
                    .padding(.horizontal, 16)
            }

            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    OutboundEmptyView(onGetStarted: {})
}
