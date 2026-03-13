import SwiftUI

struct OnboardingSuccessView: View {
    var onAllDone: () -> Void
    var onChangeSettings: () -> Void

    private var nextUpdateDate: String {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.weekday], from: today)
        let daysUntilTuesday = (3 - (components.weekday ?? 1) + 7) % 7
        var nextTuesday = calendar.date(
            byAdding: .day,
            value: daysUntilTuesday == 0 ? 7 : daysUntilTuesday,
            to: today
        ) ?? today

        var dc = calendar.dateComponents([.year, .month, .day], from: nextTuesday)
        dc.hour = 7; dc.minute = 30
        nextTuesday = calendar.date(from: dc) ?? nextTuesday

        let dayName = DateFormatter().then { $0.dateFormat = "EEEE" }.string(from: nextTuesday)
        let day     = calendar.component(.day, from: nextTuesday)
        let month   = DateFormatter().then { $0.dateFormat = "MMMM" }.string(from: nextTuesday)
        let time    = DateFormatter().then { $0.dateFormat = "h:mm a" }.string(from: nextTuesday)
            .replacingOccurrences(of: " am", with: " AM", options: .caseInsensitive)
            .replacingOccurrences(of: " pm", with: " PM", options: .caseInsensitive)

        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22:     suffix = "nd"
        case 3, 23:     suffix = "rd"
        default:        suffix = "th"
        }
        return "\(dayName) \(day)\(suffix) \(month) at \(time)"
    }

    var body: some View {
        // Use .background so the VStack respects the safe-area top exactly like every
        // other onboarding page. Children of a ZStack that carry .ignoresSafeArea()
        // expand the ZStack's layout frame to the physical screen top, shifting all
        // siblings upward and making .padding(.top, 68) inconsistent.
        VStack(spacing: 0) {

            // MARK: Header
            OnboardingHeader(
                step: nil,
                totalSteps: nil,
                title: "Awesome, all set up!"
            )
            .padding(.horizontal, 20)
            .padding(.top, 68)

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

                    Text("You shouldn't do anything.\nThe agent will send you a notification.")
                        .bodySmallStyle()
                        .foregroundColor(Color.grey50)
                        .multilineTextAlignment(.center)
                }

                // Next update
                VStack(spacing: 8) {
                    Text("Next update")
                        .bodySmallStyle()
                        .foregroundColor(Color.black)

                    Text(nextUpdateDate)
                        .bodySmallStyle()
                        .foregroundColor(Color.grey50)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 55)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)

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
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 56)
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

// MARK: - DateFormatter helper

private extension DateFormatter {
    func then(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}

#Preview {
    OnboardingSuccessView(
        onAllDone: { print("All done") },
        onChangeSettings: { print("Change settings") }
    )
}
