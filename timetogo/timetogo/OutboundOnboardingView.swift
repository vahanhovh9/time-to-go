import SwiftUI

private enum OutboundStep {
    case destinationType
    case stationSetup       // Option B only
    case arrivalTime
    case success
}

struct OutboundOnboardingView: View {
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
        case .stationSetup:    stationSetupStep
        case .arrivalTime:     arrivalTimeStep
        case .success:         successStep
        }
    }

    // MARK: - Step 1: Destination type

    private var destinationTypeStep: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 1,
                totalSteps: destinationType == .home ? 2 : 3,
                title: "Where are you going?",
                showsBackButton: true,
                onBack: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(spacing: 24) {
                DestinationCard(
                    image: "destination-home",
                    title: "Home",
                    subtitle: "Back to your home station",
                    isSelected: destinationType == .home
                ) {
                    destinationType = .home
                }

                DestinationCard(
                    image: "destination-other",
                    title: "Other place",
                    subtitle: "Any other destination",
                    isSelected: destinationType == .otherPlace
                ) {
                    destinationType = .otherPlace
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)

            Spacer(minLength: 24)

            footer {
                withAnimation {
                    currentStep = destinationType == .home ? .arrivalTime : .stationSetup
                }
            }
        }
        .background(Color.white)
    }

    // MARK: - Step 2 (Option B): Station + walk

    private var stationSetupStep: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 2,
                totalSteps: 3,
                title: "Where is your destination?",
                showsBackButton: true,
                onBack: { withAnimation { currentStep = .destinationType } }
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 38) {
                StationSearchField(label: "Destination station", selectedStation: $destStation)
                TimePicker(label: "How long do you walk from tube?", selectedValue: walkBinding)
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)

            // Takes the remaining height; the artwork scales to fit it, so it's never cut off.
            JourneyIllustration(journey: .tubeToDestination)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.top, 24)

            footer(enabled: !destStation.naptanId.isEmpty && walkMinutes != nil) {
                withAnimation { currentStep = .arrivalTime }
            }
        }
        .background(Color.white)
    }

    // MARK: - Step 2/3: Arrival time

    private var arrivalTimeStep: some View {
        let stepNum = destinationType == .home ? 2 : 3
        let totalSteps = stepNum
        let prevStep: OutboundStep = destinationType == .home ? .destinationType : .stationSetup

        return VStack(spacing: 0) {
            OnboardingHeader(
                step: stepNum,
                totalSteps: totalSteps,
                title: "When do you need to arrive?",
                showsBackButton: true,
                onBack: { withAnimation { currentStep = prevStep } }
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    ArrivalTimePicker(label: "Arrival time", selectedTime: $arrivalTime)
                        .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }

            VStack(spacing: 0) {
                Divider().background(Color.grey10)
                CustomButton(title: "Complete", style: .filled) {
                    saveAndComplete()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .background(Color.white)
        }
        .background(Color.white)
    }

    // MARK: - Success

    private var successStep: some View {
        OnboardingSuccessView(
            title: "🎉 Back home is all set! 🎉",
            message: "Anytime you open Back home it will show when to leave the office.",
            nextCommute: nextTripHome,
            arrivalTime: arrivalTime,
            onAllDone: onComplete,
            onChangeSettings: { withAnimation { currentStep = .destinationType } }
        )
    }

    /// Next office day whose trip home is still ahead (judged by the Back home arrival time,
    /// not the morning one — at 10am today's 6pm trip still counts).
    private var nextTripHome: Date {
        var s = appState.settings ?? viewModel.settings
        s.arrivalTime = arrivalTime
        return CommuteCalculationService().nextCommuteDate(from: s)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func footer(enabled: Bool = true, action: @escaping () -> Void) -> some View {
        CustomButton(title: "Next", style: .filled, action: action, isEnabled: enabled)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .background(Color.white)
    }


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

        withAnimation { currentStep = .success }
    }

    private static func time(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Destination card (Figma "card-illustration")

/// Selectable card: illustration, title + subtitle, and a check circle.
/// Selected: 2pt green border and green tick. Otherwise: 1pt grey border and empty circle.
private struct DestinationCard: View {
    var image: String
    var title: String
    var subtitle: String
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 100)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .typography(.h2)
                    Text(subtitle)
                        .typography(.large)
                }
                .foregroundColor(.grey50)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                Checkmark(state: isSelected ? .checked : .unchecked)
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.vertical, 16)
            .frame(height: 132)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color(hex: "059013") : Color.grey30, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
