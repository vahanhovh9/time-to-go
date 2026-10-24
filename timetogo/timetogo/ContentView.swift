import SwiftUI

enum SetupStep {
    case step1, step2, step3, success
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    @StateObject private var store = TFLDataStore()

    @State private var showDevMenu = false
    @State private var currentSetupStep: SetupStep = .step1
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
            } else {
                rootView
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

            #if DEBUG
            if !showDevMenu {
                Button {
                    withAnimation { showDevMenu = true }
                } label: {
                    Text("DEV")
                        .scaledFont(size: 10, weight: .medium)
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
            #endif
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
                withAnimation(.easeInOut(duration: 0.3)) { appState.finishIntro() }
            })
            .transition(.opacity)
        } else {
            setupView
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
                onNext: { withAnimation { currentSetupStep = .step2 } }
            )
            .environmentObject(store)

        case .step2:
            Setup2View(
                selectedStation: $officeStation,
                selectedWalkTime: $officeWalkTime,
                onNext: { withAnimation { currentSetupStep = .step3 } },
                onBack: { withAnimation { currentSetupStep = .step1 } }
            )
            .environmentObject(store)

        case .step3:
            Setup3View(
                arrivalTime: $arrivalTime,
                monday: $monday,
                tuesday: $tuesday,
                wednesday: $wednesday,
                thursday: $thursday,
                friday: $friday,
                onNext: { withAnimation { currentSetupStep = .success } },
                onBack: { withAnimation { currentSetupStep = .step2 } }
            )

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
                },
                onChangeSettings: {
                    withAnimation { currentSetupStep = .step1 }
                }
            )
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
