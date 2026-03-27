import SwiftUI

struct Onboarding1View: View {
    @EnvironmentObject var store: TFLDataStore

    // String bindings owned by ContentView
    @Binding var selectedLineId: String
    @Binding var selectedStationId: String
    @Binding var selectedStationName: String
    @Binding var selectedWalkTime: String

    var onNext: () -> Void = {}

    // Local display objects (derived from bindings + store)
    @State private var selectedLine: TFLLine = .placeholder
    @State private var selectedStation: TFLStopPoint = .placeholder

    private var isFormValid: Bool {
        !selectedStationId.isEmpty && selectedWalkTime != "Choose"
    }

    // MARK: - Computed dropdown items

    private var lineItems: [TFLLine] {
        [.placeholder] + store.lines
    }

    private var stationItems: [TFLStopPoint] {
        let cached = store.stations(for: selectedLine.id)
        return [.placeholder] + cached
    }

    // MARK: - Bindings for Dropdown

    private var lineBinding: Binding<TFLLine> {
        Binding(
            get: { selectedLine },
            set: { line in
                selectedLine = line
                selectedLineId = line.id
                // Reset station when line changes
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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 1,
                totalSteps: 4,
                title: "Where do you leave?"
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    Dropdown(
                        label: "Your line",
                        items: lineItems,
                        selectedItem: lineBinding
                    )
                    .padding(.horizontal, 24)

                    Dropdown(
                        label: "Your station",
                        items: stationItems,
                        selectedItem: stationBinding,
                        searchable: true
                    )
                    .padding(.horizontal, 24)
                    .disabled(selectedLine.id.isEmpty)
                    .opacity(selectedLine.id.isEmpty ? 0.5 : 1)

                    TimePicker(
                        label: "How long do you walk to tube?",
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

    // MARK: - Restore saved selections when navigating back

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
            Onboarding1View(
                selectedLineId: $lineId,
                selectedStationId: $stationId,
                selectedStationName: $stationName,
                selectedWalkTime: $walkTime,
                onNext: { print("Next tapped") }
            )
            .environmentObject(TFLDataStore(service: MockTFLService()))
        }
    }
    return PreviewWrapper()
}
