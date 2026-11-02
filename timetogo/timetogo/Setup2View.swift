import SwiftUI

struct Setup2View: View {
    @EnvironmentObject var store: TFLDataStore

    @Binding var selectedStation: TFLStopPoint
    @Binding var selectedWalkTime: String
    var homeStation: TFLStopPoint = .placeholder

    var onNext: () -> Void
    var onBack: () -> Void

    private var isFormValid: Bool {
        !selectedStation.naptanId.isEmpty && selectedWalkTime != "Choose"
    }

    var body: some View {
        SetupStepLayout(
            step: 2,
            title: "Where is the office",
            showsBackButton: true,
            onBack: onBack,
            isButtonEnabled: isFormValid,
            onButton: onNext
        ) {
            JourneyIllustration(journey: .tubeToOffice)
        } fields: {
            StationSearchField(
                label: "Office station",
                selectedStation: $selectedStation,
                excluding: [homeStation]
            )

            TimePicker(
                label: "How long do you get to your desk?",
                selectedValue: $selectedWalkTime
            )
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var station = TFLStopPoint.placeholder
        @State private var walkTime = "Choose"

        var body: some View {
            Setup2View(
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
