import SwiftUI

enum OnboardingStep {
    case step1, step2, step3, step4, success
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationService: NotificationService

    @StateObject private var store = TFLDataStore()

    @State private var showDevMenu = false
    @State private var currentOnboardingStep: OnboardingStep = .step1
    @State private var mainViewModel: MainViewModel?

    // MARK: - Onboarding state

    @State private var homeStation: TFLStopPoint = .placeholder
    @State private var homeWalkTime = "Choose"
    @State private var officeStation: TFLStopPoint = .placeholder
    @State private var officeWalkTime = "Choose"
    @State private var arrivalTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var monday = false
    @State private var tuesday = true
    @State private var wednesday = false
    @State private var thursday = true
    @State private var friday = false
    @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if showDevMenu {
                DevMenuView(
                    onDismiss: { withAnimation { showDevMenu = false } },
                    onClearCache: { mainViewModel?.loadCommute(forceRefresh: true) },
                    journeyDebugInfo: mainViewModel?.journeyDebugInfo
                )
            } else if appState.hasCompletedOnboarding {
                mainView
            } else {
                onboardingView
            }

            if !showDevMenu {
                Button {
                    withAnimation { showDevMenu = true }
                } label: {
                    Text("DEV")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.grey30, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                }
                .padding(.top, 16)
                .padding(.trailing, 24)
                .zIndex(1000)
            }
        }
        .onChange(of: notificationService.pendingDeepLink) {
            guard let action = notificationService.pendingDeepLink else { return }
            handleDeepLink(action)
            notificationService.pendingDeepLink = nil
        }
        .onAppear {
            ensureMainViewModelIfNeeded()
        }
    }

    // MARK: - Main view

    @ViewBuilder
    private var mainView: some View {
        if let vm = mainViewModel {
            MainView(viewModel: vm)
                .environmentObject(store)
                .environmentObject(appState)
        } else {
            ProgressView()
                .onAppear { ensureMainViewModelIfNeeded() }
        }
    }

    // MARK: - Onboarding navigation

    @ViewBuilder
    private var onboardingView: some View {
        switch currentOnboardingStep {
        case .step1:
            Onboarding1View(
                selectedStation: $homeStation,
                selectedWalkTime: $homeWalkTime,
                onNext: { withAnimation { currentOnboardingStep = .step2 } }
            )
            .environmentObject(store)

        case .step2:
            Onboarding2View(
                selectedStation: $officeStation,
                selectedWalkTime: $officeWalkTime,
                onNext: { withAnimation { currentOnboardingStep = .step3 } },
                onBack: { withAnimation { currentOnboardingStep = .step1 } }
            )
            .environmentObject(store)

        case .step3:
            Onboarding3View(
                arrivalTime: $arrivalTime,
                monday: $monday,
                tuesday: $tuesday,
                wednesday: $wednesday,
                thursday: $thursday,
                friday: $friday,
                onNext: { withAnimation { currentOnboardingStep = .step4 } },
                onBack: { withAnimation { currentOnboardingStep = .step2 } }
            )

        case .step4:
            Onboarding4View(
                notificationTime: $notificationTime,
                arrivalTime: arrivalTime,
                onComplete: { withAnimation { currentOnboardingStep = .success } },
                onBack: { withAnimation { currentOnboardingStep = .step3 } }
            )

        case .success:
            OnboardingSuccessView(
                onAllDone: {
                    let settings = buildUserSettings()
                    if appState.isEditingSettings {
                        appState.finishSettingsEdit(with: settings)
                    } else {
                        appState.completeOnboarding(with: settings)
                    }
                    mainViewModel = MainViewModel(settings: settings)
                },
                onChangeSettings: {
                    withAnimation { currentOnboardingStep = .step1 }
                }
            )
        }
    }

    // MARK: - Deep link routing

    private func handleDeepLink(_ action: DeepLinkAction) {
        switch action {
        case .openMain(let forceRefresh):
            ensureMainViewModelIfNeeded()
            guard let vm = mainViewModel else { return }
            if forceRefresh { vm.loadCommute(forceRefresh: true) }
        }
    }

    // MARK: - Helpers

    private func ensureMainViewModelIfNeeded() {
        guard mainViewModel == nil, let settings = appState.settings else { return }
        mainViewModel = MainViewModel(settings: settings)
    }

    private func buildUserSettings() -> UserSettings {
        var s = UserSettings()
        s.homeStationId           = homeStation.naptanId
        s.homeStationName         = homeStation.commonName
        s.homeStationLines        = homeStation.lines
        s.walkingMinutesToStation = parseMinutes(homeWalkTime)
        s.officeStationId         = officeStation.naptanId
        s.officeStationName       = officeStation.commonName
        s.officeStationLines      = officeStation.lines
        s.walkingMinutesToOffice  = parseMinutes(officeWalkTime)
        s.arrivalTime             = arrivalTime
        s.officeDays              = selectedDays
        s.notificationTime        = notificationTime
        return s
    }

    private func parseMinutes(_ value: String) -> Int {
        Int(value.replacingOccurrences(of: " min", with: "")) ?? 5
    }

    private var selectedDays: [Weekday] {
        var days: [Weekday] = []
        if monday    { days.append(.monday) }
        if tuesday   { days.append(.tuesday) }
        if wednesday { days.append(.wednesday) }
        if thursday  { days.append(.thursday) }
        if friday    { days.append(.friday) }
        return days
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(NotificationService.shared)
}
