import SwiftUI

struct Setup1View: View {
    @EnvironmentObject var store: TFLDataStore

    @Binding var selectedStation: TFLStopPoint
    @Binding var selectedWalkTime: String
    /// Already chosen as the office station (after going back from step 2).
    var officeStation: TFLStopPoint = .placeholder

    var onNext: () -> Void = {}

    private var isFormValid: Bool {
        !selectedStation.naptanId.isEmpty && selectedWalkTime != "Choose"
    }

    var body: some View {
        SetupStepLayout(
            step: 1,
            title: "Where do you live?",
            isButtonEnabled: isFormValid,
            onButton: onNext
        ) {
            JourneyIllustration(journey: .homeToTube)
        } fields: {
            StationSearchField(
                label: "Home station",
                selectedStation: $selectedStation,
                excluding: [officeStation]
            )
            .setupReveal(order: 0)

            TimePicker(
                label: "How long do you get to tube?",
                selectedValue: $selectedWalkTime,
                placeholder: "Choose (mins)"
            )
            .setupReveal(order: 1)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var station = TFLStopPoint.placeholder
        @State private var walkTime = "Choose"

        var body: some View {
            Setup1View(
                selectedStation: $station,
                selectedWalkTime: $walkTime,
                onNext: { print("Next tapped") }
            )
            .environmentObject(TFLDataStore(service: MockTFLService()))
        }
    }
    return PreviewWrapper()
}
