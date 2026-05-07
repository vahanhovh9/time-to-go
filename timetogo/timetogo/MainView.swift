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
        TabView(selection: $selectedTab) {
            inboundView
                .tabItem { Label("Inbound", systemImage: "building.2") }
                .tag(MainTab.inbound)

            outboundTabContent
                .tabItem { Label("Outbound", systemImage: "house") }
                .tag(MainTab.outbound)

            SettingsView(viewModel: viewModel)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(MainTab.settings)
        }
        .onAppear {
            applyTabBarAppearance()
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
            outboundView
        } else {
            OutboundEmptyView { showOutboundOnboarding = true }
        }
    }

    // MARK: - Inbound (home → office)

    private var inboundView: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 32) {
                OnboardingHeader(step: nil, totalSteps: nil, title: "Leave home at")
                    .padding(.horizontal, 24)
                    .padding(.top, 48)

                TimeDisplay(day: viewModel.dayLabelText, time: viewModel.leaveHomeTimeText)
                    .padding(.horizontal, 24)

                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(viewModel.serviceStatusText)
                            .bodySmallStyle()
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, -8)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .labelStyle()
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                InfoCard(items: inboundInfoItems)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .background(tabBackground)
    }

    // MARK: - Outbound (office → destination)

    private var outboundView: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 32) {
                OnboardingHeader(step: nil, totalSteps: nil, title: "Leave office at")
                    .padding(.horizontal, 24)
                    .padding(.top, 48)

                TimeDisplay(day: viewModel.dayLabelText, time: viewModel.leaveOfficeTimeText)
                    .padding(.horizontal, 24)

                Group {
                    if viewModel.isLoadingOutbound {
                        ProgressView().tint(.black)
                    } else {
                        Text(viewModel.outboundServiceStatusText)
                            .bodySmallStyle()
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, -8)

                if let error = viewModel.outboundErrorMessage {
                    Text(error)
                        .labelStyle()
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                InfoCard(items: outboundInfoItems)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .background(tabBackground)
        .onAppear {
            if viewModel.outboundResult == nil {
                viewModel.loadOutbound()
            }
        }
    }

    // MARK: - Shared background

    private var tabBackground: some View {
        ZStack {
            Color.yellow
            Image("bg-main")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    // MARK: - Tab bar styling

    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // FFF9BE background
        appearance.backgroundColor = UIColor(red: 1.0, green: 249.0 / 255.0, blue: 190.0 / 255.0, alpha: 1.0)
        // Grey50 (#3E3E3E) as 1pt top border
        appearance.shadowColor = UIColor(red: 62.0 / 255.0, green: 62.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)

        let grey50 = UIColor(red: 62.0 / 255.0, green: 62.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
        let item = UITabBarItemAppearance()
        item.normal.iconColor   = grey50
        item.normal.titleTextAttributes   = [.foregroundColor: grey50]
        item.selected.iconColor = UIColor.black
        item.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.stackedLayoutAppearance      = item
        appearance.inlineLayoutAppearance       = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance    = appearance
        UITabBar.appearance().scrollEdgeAppearance  = appearance
    }

    // MARK: - InfoCard data

    private var inboundInfoItems: [InfoItemData] {
        [
            InfoItemData(
                title: "Home station",
                subtitle: viewModel.homeStationDisplayName,
                time: viewModel.trainDepartureText,
                iconColor: Color(red: 1.0, green: 0.689, blue: 0.689),
                iconName: "house.fill"
            ),
            InfoItemData(
                title: "Tube Journey",
                subtitle: viewModel.numberOfStopsText,
                time: viewModel.journeyDurationText,
                iconColor: Color(red: 0.973, green: 0.925, blue: 0.51),
                iconName: "tram.fill"
            ),
            InfoItemData(
                title: "Work",
                subtitle: viewModel.officeStationDisplayName,
                time: viewModel.userArrivalTimeText,
                iconColor: Color(red: 0.64, green: 0.986, blue: 0.515),
                iconName: "building.2.fill"
            )
        ]
    }

    private var outboundInfoItems: [InfoItemData] {
        [
            InfoItemData(
                title: "Office station",
                subtitle: viewModel.officeStationDisplayName,
                time: viewModel.outboundTrainDepartureText,
                iconColor: Color(red: 0.64, green: 0.986, blue: 0.515),
                iconName: "building.2.fill"
            ),
            InfoItemData(
                title: "Tube Journey",
                subtitle: viewModel.outboundNumberOfStopsText,
                time: viewModel.outboundJourneyDurationText,
                iconColor: Color(red: 0.973, green: 0.925, blue: 0.51),
                iconName: "tram.fill"
            ),
            InfoItemData(
                title: viewModel.settings.outboundDestinationType == .home ? "Home" : "Destination",
                subtitle: viewModel.outboundDestinationDisplayName,
                time: viewModel.homeArrivalTimeText,
                iconColor: Color(red: 1.0, green: 0.689, blue: 0.689),
                iconName: viewModel.settings.outboundDestinationType == .home ? "house.fill" : "mappin.circle.fill"
            )
        ]
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
