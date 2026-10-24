import SwiftUI

struct Onboarding3View: View {
    @Binding var arrivalTime: Date
    @Binding var monday: Bool
    @Binding var tuesday: Bool
    @Binding var wednesday: Bool
    @Binding var thursday: Bool
    @Binding var friday: Bool

    var onNext: () -> Void
    var onBack: () -> Void

    private var isFormValid: Bool {
        monday || tuesday || wednesday || thursday || friday
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 3,
                totalSteps: 3,
                title: "When are you at the office?",
                showsBackButton: true,
                onBack: onBack
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 32) {
                ArrivalTimePicker(label: "Arrival time", selectedTime: $arrivalTime)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    DayPicker(day: "Mon", isSelected: $monday)
                    DayPicker(day: "Tue", isSelected: $tuesday)
                    DayPicker(day: "Wed", isSelected: $wednesday)
                    DayPicker(day: "Thu", isSelected: $thursday)
                    DayPicker(day: "Fri", isSelected: $friday)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)

            // Takes the remaining height; the artwork scales to fit it, so it's never cut off.
            JourneyIllustration(journey: .atDesk)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.top, 24)

            CustomButton(title: "Complete", style: .filled, action: { onNext() }, isEnabled: isFormValid)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
        }
        .background(Color.white)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var arrivalTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        @State private var monday = false
        @State private var tuesday = true
        @State private var wednesday = false
        @State private var thursday = true
        @State private var friday = false

        var body: some View {
            Onboarding3View(
                arrivalTime: $arrivalTime,
                monday: $monday,
                tuesday: $tuesday,
                wednesday: $wednesday,
                thursday: $thursday,
                friday: $friday,
                onNext: { print("Next") },
                onBack: { print("Back") }
            )
        }
    }
    return PreviewWrapper()
}
