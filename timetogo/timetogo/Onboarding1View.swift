import SwiftUI

struct Onboarding1View: View {
    @EnvironmentObject var store: TFLDataStore

    @Binding var selectedStation: TFLStopPoint
    @Binding var selectedWalkTime: String

    var onNext: () -> Void = {}

    private var isFormValid: Bool {
        !selectedStation.naptanId.isEmpty && selectedWalkTime != "Choose"
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 1,
                totalSteps: 3,
                title: "Where do you leave?"
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 38) {
                StationSearchField(
                    label: "Home station",
                    selectedStation: $selectedStation
                )

                TimePicker(
                    label: "How long do you walk to tube?",
                    selectedValue: $selectedWalkTime
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)

            // Takes the remaining height; the artwork scales to fit it, so it's never cut off.
            JourneyIllustration(journey: .homeToTube)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.top, 24)

            CustomButton(title: "Next", style: .filled, action: { onNext() }, isEnabled: isFormValid)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
        }
        .background(Color.white)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var station = TFLStopPoint.placeholder
        @State private var walkTime = "Choose"

        var body: some View {
            Onboarding1View(
                selectedStation: $station,
                selectedWalkTime: $walkTime,
                onNext: { print("Next tapped") }
            )
            .environmentObject(TFLDataStore(service: MockTFLService()))
        }
    }
    return PreviewWrapper()
}
