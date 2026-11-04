import SwiftUI

struct Setup3View: View {
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
        SetupStepLayout(
            step: 3,
            title: "When at office?",
            showsBackButton: true,
            onBack: onBack,
            buttonTitle: "Complete",
            isButtonEnabled: isFormValid,
            onButton: onNext,
            fieldSpacing: 48
        ) {
            JourneyIllustration(journey: .atDesk)
        } fields: {
            ArrivalTimePicker(label: "Arrival time", selectedTime: $arrivalTime)
                .setupReveal(order: 0)

            HStack(spacing: 12) {
                DayChip(day: "Mo", isSelected: $monday)
                DayChip(day: "Tu", isSelected: $tuesday)
                DayChip(day: "We", isSelected: $wednesday)
                DayChip(day: "Th", isSelected: $thursday)
                DayChip(day: "Fr", isSelected: $friday)
            }
            .setupReveal(order: 1)
        }
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
            Setup3View(
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
