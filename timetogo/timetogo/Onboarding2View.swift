import SwiftUI

struct Onboarding2View: View {
    @EnvironmentObject var store: TFLDataStore

    @Binding var selectedStation: TFLStopPoint
    @Binding var selectedWalkTime: String

    var onNext: () -> Void
    var onBack: () -> Void

    private var isFormValid: Bool {
        !selectedStation.naptanId.isEmpty && selectedWalkTime != "Choose"
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 2,
                totalSteps: 4,
                title: "Where do you work?",
                showsBackButton: true,
                onBack: onBack
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    StationSearchField(
                        label: "Office's station",
                        selectedStation: $selectedStation
                    )
                    .padding(.horizontal, 24)

                    TimePicker(
                        label: "How long do you walk to office?",
                        selectedValue: $selectedWalkTime
                    )
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }

            VStack(spacing: 0) {
                Divider().background(Color.grey10)
                VStack(spacing: 16) {
                    CustomButton(title: "Next", style: .filled, action: { onNext() }, isEnabled: isFormValid)
                }
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
        @State private var station = TFLStopPoint.placeholder
        @State private var walkTime = "Choose"

        var body: some View {
            Onboarding2View(
                selectedStation: $station,
                selectedWalkTime: $walkTime,
                onNext: { print("Next") },
                onBack: { print("Back") }
            )
            .environmentObject(TFLDataStore(service: MockTFLService()))
        }
    }
    return PreviewWrapper()
}
