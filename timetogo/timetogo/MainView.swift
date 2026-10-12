import SwiftUI

enum MainTab {
    case inbound, outbound, settings
}

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: TFLDataStore
    @ObservedObject var viewModel: MainViewModel

    @State private var selectedTab: MainTab = .inbound
    @State private var showOutboundOnboarding = false

    var body: some View {
        Group {
            switch selectedTab {
            case .inbound:  CommuteHomeView(direction: .toOffice, viewModel: viewModel)
            case .outbound: outboundTabContent
            case .settings: SettingsView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MainTabBar(selection: $selectedTab)
        }
        .onAppear {
            viewModel.loadCommute()
        }
        .fullScreenCover(isPresented: $showOutboundOnboarding) {
            OutboundOnboardingView(viewModel: viewModel) {
                showOutboundOnboarding = false
            }
            .environmentObject(appState)
            .environmentObject(store)
        }
    }

    // MARK: - Outbound tab

    @ViewBuilder
    private var outboundTabContent: some View {
        if viewModel.settings.outboundEnabled {
            CommuteHomeView(direction: .backHome, viewModel: viewModel)
        } else {
            OutboundEmptyView { showOutboundOnboarding = true }
        }
    }
}

#Preview {
    let settings = UserSettings()
    let vm = MainViewModel(
        settings: settings,
        calculationService: CommuteCalculationService(tflService: MockTFLService())
    )
    return MainView(viewModel: vm)
        .environmentObject(AppState())
        .environmentObject(TFLDataStore(service: MockTFLService()))
}
