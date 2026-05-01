import SwiftUI

enum OnboardingStep {
    case step1, step2, step3, step4, success
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationService: NotificationService

    @StateObject private var store = TFLDataStore()

    @State private var showDesignSystem = false
    @State private var currentOnboardingStep: OnboardingStep = .step1
    @State private var mainViewModel: MainViewModel?
    /// Bumped each time the user enters settings-edit mode.
    /// Forces SwiftUI to recreate onboarding views so their internal @State
    /// (selectedLine, selectedStation) gets re-derived from the bindings.
    @State private var onboardingSessionId = UUID()

    // MARK: - Onboarding state (persists when navigating between steps)

    // Step 1 — Home
    @State private var homeStation: TFLStopPoint = .placeholder
    @State private var homeWalkTime = "Choose"

    // Step 2 — Office
    @State private var officeStation: TFLStopPoint = .placeholder
    @State private var officeWalkTime = "Choose"

    // Step 3 — Schedule
    @State private var arrivalTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var monday = false
    @State private var tuesday = true
    @State private var wednesday = false
    @State private var thursday = true
    @State private var friday = false

    // Step 4 — Notification
    @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if showDesignSystem {
                DesignSystemView()
            } else if appState.hasCompletedOnboarding {
                mainView
            } else {
                onboardingView
                    .id(onboardingSessionId)
            }

            Button {
                withAnimation { showDesignSystem.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showDesignSystem ? "app.fill" : "paintpalette.fill")
                        .font(.system(size: 9, weight: .medium))
                    Text(showDesignSystem ? "App" : "Design System")
                        .font(.system(size: 10, weight: .medium))
                }
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
        .onChange(of: notificationService.pendingDeepLink) {
            guard let action = notificationService.pendingDeepLink else { return }
            handleDeepLink(action)
            notificationService.pendingDeepLink = nil
        }
        .onAppear {
            ensureMainViewModelIfNeeded()
        }
    }

    // MARK: - Main view (post-onboarding)

    @ViewBuilder
    private var mainView: some View {
        if let vm = mainViewModel {
            MainView(viewModel: vm, onChangeSettings: {
                prefillFromSavedSettings()
                onboardingSessionId = UUID()   // force fresh view identity
                withAnimation {
                    appState.enterSettingsEditMode()
                    currentOnboardingStep = .step1
                }
            })
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
                    withAnimation {
                        currentOnboardingStep = .step1
                    }
                }
            )
        }
    }

    // MARK: - §11.8 Deep link routing

    private func handleDeepLink(_ action: DeepLinkAction) {
        switch action {
        case .openMain(let forceRefresh):
            ensureMainViewModelIfNeeded()
            guard let vm = mainViewModel else { return }
            if forceRefresh {
                vm.loadCommute(forceRefresh: true)
            }
        }
    }

    // MARK: - Helpers

    private func ensureMainViewModelIfNeeded() {
        guard mainViewModel == nil, let settings = appState.settings else { return }
        mainViewModel = MainViewModel(settings: settings)
    }

    /// Populates all onboarding @State fields from the saved UserSettings
    /// so the user sees their current choices pre-filled when editing.
    private func prefillFromSavedSettings() {
        guard let s = appState.settings else { return }

        homeStation  = TFLStopPoint(naptanId: s.homeStationId, commonName: s.homeStationName, lines: s.homeStationLines)
        homeWalkTime = s.walkingMinutesToStation > 0 ? "\(s.walkingMinutesToStation) min" : "Choose"

        officeStation  = TFLStopPoint(naptanId: s.officeStationId, commonName: s.officeStationName, lines: s.officeStationLines)
        officeWalkTime = s.walkingMinutesToOffice > 0 ? "\(s.walkingMinutesToOffice) min" : "Choose"

        arrivalTime      = s.arrivalTime
        notificationTime = s.notificationTime

        let days = Set(s.officeDays)
        monday    = days.contains(.monday)
        tuesday   = days.contains(.tuesday)
        wednesday = days.contains(.wednesday)
        thursday  = days.contains(.thursday)
        friday    = days.contains(.friday)
    }

    private func buildUserSettings() -> UserSettings {
        var s = UserSettings()
        s.homeStationId          = homeStation.naptanId
        s.homeStationName        = homeStation.commonName
        s.homeStationLines       = homeStation.lines
        s.walkingMinutesToStation = parseMinutes(homeWalkTime)
        s.officeStationId        = officeStation.naptanId
        s.officeStationName      = officeStation.commonName
        s.officeStationLines     = officeStation.lines
        s.walkingMinutesToOffice  = parseMinutes(officeWalkTime)
        s.arrivalTime            = arrivalTime
        s.officeDays             = selectedDays
        s.notificationTime       = notificationTime
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
