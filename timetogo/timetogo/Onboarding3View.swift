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
                totalSteps: 4,
                title: "When do you arrive?",
                showsBackButton: true,
                onBack: onBack
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    ArrivalTimePicker(label: "Office", selectedTime: $arrivalTime)
                        .padding(.horizontal, 24)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        DayPicker(day: "Monday",    isSelected: $monday)
                        DayPicker(day: "Tuesday",   isSelected: $tuesday)
                        DayPicker(day: "Wednesday", isSelected: $wednesday)
                        DayPicker(day: "Thursday",  isSelected: $thursday)
                        DayPicker(day: "Friday",    isSelected: $friday)
                        Color.clear.frame(height: 56)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Spacer(minLength: 40)
                }
            }

            VStack(spacing: 0) {
                Divider().background(Color.grey10)
                CustomButton(title: "Next", style: .filled, action: { onNext() }, isEnabled: isFormValid)
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
