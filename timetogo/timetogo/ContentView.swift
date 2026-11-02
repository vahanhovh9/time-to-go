import SwiftUI

enum SetupStep {
    case step1, step2, step3, success
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    @StateObject private var store = TFLDataStore()

    @State private var showDevMenu = false
    @State private var currentSetupStep: SetupStep = .step1
    /// Which way the last step change went; the new illustration slides in from that side.
    @State private var setupForward = true
    /// Raised on every step change, so the incoming step sits above the outgoing one.
    @State private var setupLayer: Double = 0
    @State private var mainViewModel: MainViewModel?
    /// Train loading screen at launch, until the first commute result (or error) is in.
    @State private var showsLaunchLoading = true
    /// DEV preview of the loading screen: pretends loading finishes at this time.
    @State private var loadingPreviewEnds: Date?

    // MARK: - Setup state

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

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            #if DEBUG
            // Settings shows the DEV button. The menu covers the app instead of replacing it,
            // so closing it goes back to Settings rather than the first tab.
            rootView
                .environment(\.openDevMenu) { withAnimation { showDevMenu = true } }

            if showDevMenu {
                DevMenuView(
                    onDismiss: { withAnimation { showDevMenu = false } },
                    onClearCache: { mainViewModel?.loadCommute(forceRefresh: true) },
                    onPreviewLoading: {
                        loadingPreviewEnds = Date().addingTimeInterval(3)
                        showsLaunchLoading = true
                    },
                    journeyDebugInfo: mainViewModel?.journeyDebugInfo
                )
                .zIndex(1000)
            }
            #else
            rootView
            #endif

            if showsLaunchLoading && appState.hasCompletedSetup {
                LoadingView(
                    isReady: {
                        if let end = loadingPreviewEnds { return Date() >= end }
                        guard let vm = mainViewModel else { return false }
                        return vm.commuteResult != nil || vm.errorMessage != nil
                    },
                    onDone: { animated in
                        loadingPreviewEnds = nil
                        if animated {
                            withAnimation(.easeOut(duration: 0.3)) { showsLaunchLoading = false }
                        } else {
                            showsLaunchLoading = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(2000)
            }
        }
        .onAppear {
            ensureMainViewModelIfNeeded()
            // Only a returning user loads a commute at launch; setup starts straight away.
            if !appState.hasCompletedSetup { showsLaunchLoading = false }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if appState.hasCompletedSetup {
            mainView
        } else if !appState.hasSeenIntro && !appState.isEditingSettings {
            IntroView(onFinish: {
                restartSetup()
                withAnimation(.easeInOut(duration: 0.3)) { appState.finishIntro() }
            })
            .transition(.opacity)
        } else {
            setupView
                .environment(\.setupArtworkFrom, setupForward ? 40 : -40)
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

    // MARK: - Setup navigation

    @ViewBuilder
    private var setupView: some View {
        switch currentSetupStep {
        case .step1:
            Setup1View(
                selectedStation: $homeStation,
                selectedWalkTime: $homeWalkTime,
                officeStation: officeStation,
                onNext: { go(to: .step2) }
            )
            .environmentObject(store)
            .setupStepTransition(layer: setupLayer)

        case .step2:
            Setup2View(
                selectedStation: $officeStation,
                selectedWalkTime: $officeWalkTime,
                homeStation: homeStation,
                onNext: { go(to: .step3) },
                onBack: { go(to: .step1) }
            )
            .environmentObject(store)
            .setupStepTransition(layer: setupLayer)

        case .step3:
            Setup3View(
                arrivalTime: $arrivalTime,
                monday: $monday,
                tuesday: $tuesday,
                wednesday: $wednesday,
                thursday: $thursday,
                friday: $friday,
                onNext: { go(to: .success) },
                onBack: { go(to: .step2) }
            )
            .setupStepTransition(layer: setupLayer)

        case .success:
            SetupSuccessView(
                nextCommute: CommuteCalculationService().nextCommuteDate(from: buildUserSettings()),
                arrivalTime: arrivalTime,
                onAllDone: {
                    let settings = buildUserSettings()
                    if appState.isEditingSettings {
                        appState.finishSettingsEdit(with: settings)
                    } else {
                        appState.completeSetup(with: settings)
                    }
                    mainViewModel = MainViewModel(settings: settings)
                }
            )
            .setupStepTransition(layer: setupLayer)
        }
    }

    private func go(to step: SetupStep) {
        let order: [SetupStep] = [.step1, .step2, .step3, .success]
        setupForward = (order.firstIndex(of: step) ?? 0) > (order.firstIndex(of: currentSetupStep) ?? 0)
        withAnimation {
            setupLayer += 1
            currentSetupStep = step
        }
    }

    // MARK: - Helpers

    /// A reset returns to the intro with this view still alive, so its setup state must be cleared.
    private func restartSetup() {
        currentSetupStep = .step1
        homeStation = .placeholder
        homeWalkTime = "Choose"
        officeStation = .placeholder
        officeWalkTime = "Choose"
        arrivalTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        monday = false
        tuesday = true
        wednesday = false
        thursday = true
        friday = false
    }

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
}
