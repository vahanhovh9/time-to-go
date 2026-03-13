import SwiftUI

enum OnboardingStep {
    case step1, step2, step3, step4, success
}

struct ContentView: View {
    // §11.8: Observes notification taps → routes to MainView.
    // No business logic here; all routing decisions are made in NotificationService.
    @EnvironmentObject private var notificationService: NotificationService

    @StateObject private var store = TFLDataStore()

    @State private var showDesignSystem = false
    @State private var showMain = false
    @State private var currentOnboardingStep: OnboardingStep = .step1
    @State private var mainViewModel: MainViewModel?

    // MARK: - Onboarding state (persists when navigating back)

    // Step 1 — Home
    @State private var homeLineId = ""
    @State private var homeStationId = ""
    @State private var homeStationName = ""
    @State private var homeWalkTime = "Choose"

    // Step 2 — Office
    @State private var officeLineId = ""
    @State private var officeStationId = ""
    @State private var officeStationName = ""
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
            } else if showMain, let vm = mainViewModel {
                MainView(viewModel: vm, onChangeSettings: {
                    withAnimation {
                        showMain = false
                        currentOnboardingStep = .step1
                    }
                })
            } else {
                onboardingView
            }

            Button {
                withAnimation { showDesignSystem.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showDesignSystem ? "app.fill" : "paintpalette.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text(showDesignSystem ? "App" : "Design System")
                        .labelStyle()
                }
                .foregroundColor(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
            .zIndex(1000)
        }
        // §11.8: Route notification taps to the main screen.
        // All routing decisions (forceRefresh) are made in NotificationService — not here.
        .onChange(of: notificationService.pendingDeepLink) {
            guard let action = notificationService.pendingDeepLink else { return }
            handleDeepLink(action)
            notificationService.pendingDeepLink = nil   // consume so it doesn't retrigger
        }
    }

    // MARK: - Onboarding navigation

    @ViewBuilder
    private var onboardingView: some View {
        switch currentOnboardingStep {
        case .step1:
            Onboarding1View(
                selectedLineId: $homeLineId,
                selectedStationId: $homeStationId,
                selectedStationName: $homeStationName,
                selectedWalkTime: $homeWalkTime,
                onNext: { withAnimation { currentOnboardingStep = .step2 } }
            )
            .environmentObject(store)

        case .step2:
            Onboarding2View(
                selectedLineId: $officeLineId,
                selectedStationId: $officeStationId,
                selectedStationName: $officeStationName,
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
                    settings.save()
                    mainViewModel = MainViewModel(settings: settings)
                    withAnimation { showMain = true }
                },
                onChangeSettings: {
                    withAnimation {
                        showMain = false
                        currentOnboardingStep = .step1
                    }
                }
            )
        }
    }

    // MARK: - §11.8 Deep link routing (navigation only — no business logic)

    private func handleDeepLink(_ action: DeepLinkAction) {
        switch action {
        case .openMain(let forceRefresh):
            // Ensure we have a ViewModel to show. If the user hasn't completed
            // onboarding yet, UserSettings.load() will return nil and we skip routing.
            if mainViewModel == nil, let settings = UserSettings.load() {
                mainViewModel = MainViewModel(settings: settings)
            }
            guard let vm = mainViewModel else { return }

            withAnimation { showMain = true }

            if forceRefresh {
                // Case B tap (§11.8): no active cache → force immediate recalculation.
                vm.loadCommute(forceRefresh: true)
            }
            // Case A tap: active cache exists; MainView will display it via loadCommute()
            // called in its .onAppear without recalculating (forceRefresh defaults to false).
        }
    }

    // MARK: - Assemble UserSettings from collected state

    private func buildUserSettings() -> UserSettings {
        var s = UserSettings()
        s.homeLineId            = homeLineId
        s.homeStationId         = homeStationId
        s.homeStationName       = homeStationName
        s.walkingMinutesToStation = parseMinutes(homeWalkTime)
        s.officeLineId          = officeLineId
        s.officeStationId       = officeStationId
        s.officeStationName     = officeStationName
        s.walkingMinutesToOffice = parseMinutes(officeWalkTime)
        s.arrivalTime           = arrivalTime
        s.officeDays            = selectedDays
        s.notificationTime      = notificationTime
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
}
