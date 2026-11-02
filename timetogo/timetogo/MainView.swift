import SwiftUI

enum MainTab {
    case inbound, outbound, settings
}

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: TFLDataStore
    @ObservedObject var viewModel: MainViewModel

    @State private var selectedTab: MainTab = .inbound
    @State private var showOutboundSetup = false

    /// Links the Back home card's artwork, card and button to setup's, so they move into place.
    @Namespace private var outboundMorph
    /// Raised on every switch, so the incoming screen sits above the outgoing one.
    @State private var morphLayer: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            // Back home setup takes the whole screen.
            if !showOutboundSetup {
                MainTabBar(selection: $selectedTab)
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            viewModel.loadCommute()
        }
    }

    // MARK: - Outbound tab

    @ViewBuilder
    private var outboundTabContent: some View {
        Group {
            // No fade between the card and setup: the shared parts move instead. The incoming
            // screen is drawn whole on top, so the outgoing one never shows through.
            if showOutboundSetup {
                OutboundSetupView(viewModel: viewModel) { setOutboundSetup(false) }
                    .transition(morphTransition)
                    .zIndex(morphLayer)
            } else if viewModel.settings.outboundEnabled {
                CommuteHomeView(direction: .backHome, viewModel: viewModel)
            } else {
                OutboundEmptyView { setOutboundSetup(true) }
                    .transition(morphTransition)
                    .zIndex(morphLayer)
            }
        }
        // With Reduce Motion the screens just cross-fade.
        .environment(\.setupMorph, reduceMotion ? nil : outboundMorph)
    }

    private var morphTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .identity, removal: .opacity)
    }

    private func setOutboundSetup(_ shown: Bool) {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: 0.6)) {
            morphLayer += 1
            showOutboundSetup = shown
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
