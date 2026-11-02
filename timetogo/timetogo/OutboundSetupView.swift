import SwiftUI

private enum OutboundStep {
    case destinationType
    case details            // Arrival time; station and walk too for somewhere else
}

struct OutboundSetupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: TFLDataStore
    var viewModel: MainViewModel
    var onComplete: () -> Void

    // MARK: - Flow state

    @State private var currentStep: OutboundStep = .destinationType
    @State private var destinationType: OutboundDestinationType = .home

    // Station (Option B only)
    @State private var destStation: TFLStopPoint = .placeholder
    @State private var walkMinutes: Int?

    // Arrival
    @State private var arrivalTime: Date = Self.time(18, 0)

    // MARK: - Body

    var body: some View {
        switch currentStep {
        case .destinationType: destinationTypeStep
        case .details:         detailsStep
        }
    }

    // MARK: - Step 1: Destination type

    private var destinationTypeStep: some View {
        SetupStepLayout(
            step: 1,
            totalSteps: 2,
            title: "Where are you heading?",
            showsBackButton: true,
            onBack: onComplete,
            onButton: { withAnimation { currentStep = .details } }
        ) {
            JourneyIllustration(journey: .headingOut)
        } fields: {
            VStack(spacing: 12) {
                DestinationCard(
                    title: "Home",
                    subtitle: "Back to your home station",
                    isSelected: destinationType == .home
                ) {
                    destinationType = .home
                }

                DestinationCard(
                    title: "Somewhere else",
                    subtitle: "Any other destination",
                    isSelected: destinationType == .otherPlace
                ) {
                    destinationType = .otherPlace
                }
            }
        }
    }

    // MARK: - Step 2: Details

    private var detailsStep: some View {
        SetupStepLayout(
            step: 2,
            totalSteps: 2,
            title: "When do you need to arrive?",
            showsBackButton: true,
            onBack: { withAnimation { currentStep = .destinationType } },
            buttonTitle: "Complete",
            isButtonEnabled: isDetailsValid,
            onButton: saveAndComplete
        ) {
            JourneyIllustration(journey: .tubeToDestination)
        } fields: {
            if destinationType == .otherPlace {
                StationSearchField(label: "Destination station", selectedStation: $destStation, excluding: [officeStation])
                TimePicker(label: "How long is your walk from the tube?", selectedValue: walkBinding)
            }
            ArrivalTimePicker(label: "Arrival time", selectedTime: $arrivalTime)
        }
    }

    private var isDetailsValid: Bool {
        destinationType == .home || (!destStation.naptanId.isEmpty && walkMinutes != nil)
    }

    private var officeStation: TFLStopPoint {
        let s = appState.settings ?? viewModel.settings
        return TFLStopPoint(naptanId: s.officeStationId, commonName: s.officeStationName, lines: s.officeStationLines)
    }

    // MARK: - Helpers

    private var walkBinding: Binding<String> {
        Binding(
            get: { walkMinutes.map { "\($0) min" } ?? "Choose" },
            set: { walkMinutes = Int($0.replacingOccurrences(of: " min", with: "")) }
        )
    }

    // MARK: - Save

    private func saveAndComplete() {
        guard var s = appState.settings else { return }

        s.outboundEnabled          = true
        s.outboundDestinationType  = destinationType
        s.outboundArrivalTime      = arrivalTime

        switch destinationType {
        case .home:
            s.outboundDestinationStationId    = s.homeStationId
            s.outboundDestinationStationName  = s.homeStationName
            s.outboundDestinationStationLines = s.homeStationLines
            s.outboundWalkingTimeFromStation  = s.walkingMinutesToStation
        case .otherPlace:
            s.outboundDestinationStationId    = destStation.naptanId
            s.outboundDestinationStationName  = destStation.commonName
            s.outboundDestinationStationLines = destStation.lines
            s.outboundWalkingTimeFromStation  = walkMinutes ?? 5
        }

        appState.updateSettings(s)
        viewModel.updateSettings(s)

        onComplete()
    }

    private static func time(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Destination card (Figma "card-illustration")

/// Selectable card: title + subtitle and a check circle.
/// Selected: 2pt Grey 50 border and green tick. Otherwise: 1pt Grey 29 border and empty circle.
private struct DestinationCard: View {
    var title: String
    var subtitle: String
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .typography(.h3)
                        .foregroundColor(.grey50)
                    Text(subtitle)
                        .typography(.large)
                        .foregroundColor(.grey40)
                }
                // 104pt card minus its padding, so the text stays vertically centred.
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)

                Checkmark(state: isSelected ? .checked : .unchecked)
            }
            .padding(.leading, 24)
            .padding(.trailing, 12)
            .padding(.vertical, 16)
            .frame(minHeight: 104)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.grey50 : Color.grey29, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
