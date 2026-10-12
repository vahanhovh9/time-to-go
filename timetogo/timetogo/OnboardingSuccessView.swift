import SwiftUI

struct OnboardingSuccessView: View {
    var onAllDone: () -> Void
    var onChangeSettings: () -> Void

    var body: some View {
        // Use .background so the VStack respects the safe-area top exactly like every
        // other onboarding page. Children of a ZStack that carry .ignoresSafeArea()
        // expand the ZStack's layout frame to the physical screen top, shifting all
        // siblings upward and making header top padding inconsistent.
        VStack(spacing: 0) {

            // MARK: Header
            OnboardingHeader(
                step: nil,
                totalSteps: nil,
                title: "Awesome, all set up!"
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            Spacer()

            // MARK: White card
            VStack(spacing: 38) {

                Text("🎉")
                    .font(.system(size: 62))

                // What's next
                VStack(spacing: 8) {
                    Text("What's next?")
                        .h3Style()
                        .foregroundColor(Color.black)

                    Text("Open TimeToGo whenever\nyou're heading out.")
                        .bodySmallStyle()
                        .foregroundColor(Color.grey50)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 55)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 24)

            Spacer()

            // MARK: Buttons
            VStack(spacing: 8) {
                CustomButton(title: "All done", style: .filled) {
                    onAllDone()
                }

                CustomButton(title: "Change your settings", style: .outline) {
                    onChangeSettings()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Color.yellow
                Image("bg-main")
                    .resizable()
                    .scaledToFill()
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    OnboardingSuccessView(
        onAllDone: { print("All done") },
        onChangeSettings: { print("Change settings") }
    )
}
