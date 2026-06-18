import SwiftUI

struct Onboarding4View: View {
    @Binding var notificationTime: Date
    var arrivalTime: Date

    var onComplete: () -> Void
    var onBack: () -> Void

    private var maxNotificationTime: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: arrivalTime.addingTimeInterval(-30 * 60))
        return cal.date(bySettingHour: comps.hour ?? 8, minute: comps.minute ?? 30, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 4,
                totalSteps: 4,
                title: "When get notified?",
                showsBackButton: true,
                onBack: onBack
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    ArrivalTimePicker(
                        label: "For office",
                        selectedTime: $notificationTime,
                        maximumTime: maxNotificationTime
                    )
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }

            VStack(spacing: 0) {
                Divider().background(Color.grey10)
                CustomButton(title: "Complete", style: .filled) { onComplete() }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
            }
            .background(Color.white)
        }
        .background(Color.white)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()

        var body: some View {
            Onboarding4View(
                notificationTime: $notificationTime,
                arrivalTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
                onComplete: { print("Complete") },
                onBack: { print("Back") }
            )
        }
    }
    return PreviewWrapper()
}
