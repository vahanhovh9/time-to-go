import SwiftUI

struct Onboarding2View: View {
    @EnvironmentObject var store: TFLDataStore

    @Binding var selectedLineId: String
    @Binding var selectedStationId: String
    @Binding var selectedStationName: String
    @Binding var selectedWalkTime: String

    var onNext: () -> Void
    var onBack: () -> Void

    @State private var selectedLine: TFLLine = .placeholder
    @State private var selectedStation: TFLStopPoint = .placeholder

    private var isFormValid: Bool {
        !selectedStationId.isEmpty && selectedWalkTime != "Choose"
    }

    private var lineItems: [TFLLine] {
        [.placeholder] + store.lines
    }

    private var stationItems: [TFLStopPoint] {
        let cached = store.stations(for: selectedLine.id)
        return [.placeholder] + cached
    }

    private var lineBinding: Binding<TFLLine> {
        Binding(
            get: { selectedLine },
            set: { line in
                selectedLine = line
                selectedLineId = line.id
                selectedStation = .placeholder
                selectedStationId = ""
                selectedStationName = ""
                if !line.id.isEmpty {
                    store.loadStations(for: line.id)
                }
            }
        )
    }

    private var stationBinding: Binding<TFLStopPoint> {
        Binding(
            get: { selectedStation },
            set: { stop in
                selectedStation = stop
                selectedStationId = stop.naptanId
                selectedStationName = stop.commonName
            }
        )
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

                    Dropdown(
                        label: "Office's line",
                        items: lineItems,
                        selectedItem: lineBinding
                    )
                    .padding(.horizontal, 24)

                    Dropdown(
                        label: "Office's station",
                        items: stationItems,
                        selectedItem: stationBinding,
                        searchable: true
                    )
                    .padding(.horizontal, 24)
                    .disabled(selectedLine.id.isEmpty)
                    .opacity(selectedLine.id.isEmpty ? 0.5 : 1)

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
        .onAppear {
            store.loadLines()
            restoreSelections()
        }
        .onChange(of: store.lines) { restoreSelections() }
        .onChange(of: store.stationsCache) { restoreStationSelection() }
    }

    private func restoreSelections() {
        if selectedLine.id.isEmpty, !selectedLineId.isEmpty,
           let line = store.line(for: selectedLineId) {
            selectedLine = line
            store.loadStations(for: selectedLineId)
        }
        restoreStationSelection()
    }

    private func restoreStationSelection() {
        if selectedStation.naptanId.isEmpty, !selectedStationId.isEmpty {
            if let stop = store.station(naptanId: selectedStationId, lineId: selectedLineId) {
                selectedStation = stop
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var lineId = ""
        @State private var stationId = ""
        @State private var stationName = ""
        @State private var walkTime = "Choose"

        var body: some View {
            Onboarding2View(
                selectedLineId: $lineId,
                selectedStationId: $stationId,
                selectedStationName: $stationName,
                selectedWalkTime: $walkTime,
                onNext: { print("Next") },
                onBack: { print("Back") }
            )
            .environmentObject(TFLDataStore(service: MockTFLService()))
        }
    }
    return PreviewWrapper()
}
