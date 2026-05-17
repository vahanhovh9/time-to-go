import SwiftUI

private enum OutboundStep {
    case destinationType
    case stationSetup       // Option B only
    case arrivalTime
    case notificationTime
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
    @State private var walkMinutes: Int = 5

    // Arrival
    @State private var arrivalTime: Date = Self.time(18, 0)

    // Notification
    @State private var notificationTime: Date = Self.time(16, 0)

    // MARK: - Body

    var body: some View {
        switch currentStep {
        case .destinationType: destinationTypeStep
        case .stationSetup:    stationSetupStep
        case .arrivalTime:     arrivalTimeStep
        case .notificationTime: notificationStep
        case .success:         successStep
        }
    }

    // MARK: - Step 1: Destination type

    private var destinationTypeStep: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                step: 1,
                totalSteps: destinationType == .home ? 3 : 4,
                title: "Where are you going?",
                showsBackButton: true,
                onBack: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer(minLength: 40)

                    destinationOption(
                        icon: "house.fill",
                        title: "Home",
                        subtitle: "Back to your home station",
                        isSelected: destinationType == .home
                    ) {
                        destinationType = .home
                    }
                    .padding(.horizontal, 24)

                    destinationOption(
                        icon: "mappin.circle.fill",
                        title: "Other place",
                        subtitle: "Any other tube destination",
                        isSelected: destinationType == .otherPlace
                    ) {
                        destinationType = .otherPlace
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }

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
                totalSteps: 4,
                title: "Where are you going?",
                showsBackButton: true,
                onBack: { withAnimation { currentStep = .destinationType } }
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    StationSearchField(label: "Destination station", selectedStation: $destStation)
                        .padding(.horizontal, 24)

                    TimePicker(label: "Walk from station", selectedValue: walkBinding)
                        .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }

            footer(enabled: !destStation.naptanId.isEmpty) {
                withAnimation { currentStep = .arrivalTime }
            }
        }
        .background(Color.white)
    }

    // MARK: - Step 2/3: Arrival time

    private var arrivalTimeStep: some View {
        let stepNum = destinationType == .home ? 2 : 3
        let totalSteps = destinationType == .home ? 3 : 4
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
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    ArrivalTimePicker(label: "Arrival time", selectedTime: $arrivalTime)
                        .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }

            footer { withAnimation { currentStep = .notificationTime } }
        }
        .background(Color.white)
    }

    // MARK: - Step 3/4: Notification

    private var notificationStep: some View {
        let stepNum = destinationType == .home ? 3 : 4
        let totalSteps = stepNum

        return VStack(spacing: 0) {
            OnboardingHeader(
                step: stepNum,
                totalSteps: totalSteps,
                title: "When get notified?",
                showsBackButton: true,
                onBack: { withAnimation { currentStep = .arrivalTime } }
            )
            .padding(.horizontal, 24)
            .padding(.top, 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 40)

                    ArrivalTimePicker(
                        label: "Pick a time",
                        selectedTime: $notificationTime,
                        maximumTime: maxNotificationTime
                    )
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
        VStack(spacing: 0) {
            OnboardingHeader(step: nil, totalSteps: nil, title: "Outbound is all set!")
                .padding(.horizontal, 24)
                .padding(.top, 48)

            Spacer()

            VStack(spacing: 38) {
                Text("🎉")
                    .font(.system(size: 62))

                VStack(spacing: 8) {
                    Text("What's next?")
                        .h3Style()
                        .foregroundColor(Color.black)

                    Text("You shouldn't do anything.\nWe'll tell you when to leave work.")
                        .bodySmallStyle()
                        .foregroundColor(Color.grey50)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 55)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 24)

            Spacer()

            CustomButton(title: "Got it", style: .filled) {
                onComplete()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Color.yellow
                Image("bg-main")
                    .resizable()
                    .scaledToFill()
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func destinationOption(
        icon: String,
        title: String,
        subtitle: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(width: 32)
                    .foregroundColor(isSelected ? .white : .black)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .black)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? Color.white.opacity(0.75) : Color.grey30)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.black : Color.grey10)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.black : Color.grey30, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func footer(enabled: Bool = true, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Divider().background(Color.grey10)
            CustomButton(title: "Next", style: .filled, action: action, isEnabled: enabled)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
        }
        .background(Color.white)
    }

    private var maxNotificationTime: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: arrivalTime.addingTimeInterval(-30 * 60))
        return cal.date(bySettingHour: comps.hour ?? 17, minute: comps.minute ?? 30, second: 0, of: Date()) ?? Date()
    }

    private var walkBinding: Binding<String> {
        Binding(
            get: { "\(walkMinutes) min" },
            set: { walkMinutes = Int($0.replacingOccurrences(of: " min", with: "")) ?? 5 }
        )
    }

    // MARK: - Save

    private func saveAndComplete() {
        guard var s = appState.settings else { return }

        s.outboundEnabled          = true
        s.outboundDestinationType  = destinationType
        s.outboundArrivalTime      = arrivalTime
        s.outboundNotificationTime = notificationTime
        s.outboundNotificationDays = s.officeDays   // always mirrors inbound days

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
            s.outboundWalkingTimeFromStation  = walkMinutes
        }

        appState.updateSettings(s)
        viewModel.updateSettings(s)

        withAnimation { currentStep = .success }
    }

    private static func time(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}
