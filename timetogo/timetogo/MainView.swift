import SwiftUI

enum MainTab {
    case inbound, outbound, settings
}

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    var onChangeSettings: () -> Void

    @State private var selectedTab: MainTab = .inbound

    var body: some View {
        TabView(selection: tabBinding) {
            inboundView
                .tabItem { Label("Inbound", systemImage: "building.2") }
                .tag(MainTab.inbound)

            outboundView
                .tabItem { Label("Outbound", systemImage: "house") }
                .tag(MainTab.outbound)

            Color.clear
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(MainTab.settings)
        }
        .onAppear {
            applyTabBarAppearance()
            viewModel.loadCommute()
        }
    }

    // Intercepts Settings tap — never actually switches to that tab.
    private var tabBinding: Binding<MainTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == .settings {
                    onChangeSettings()
                } else {
                    selectedTab = newTab
                }
            }
        )
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

    // MARK: - Outbound (office → home)

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
        // FFF9BE
        appearance.backgroundColor = UIColor(red: 1.0, green: 249.0 / 255.0, blue: 190.0 / 255.0, alpha: 1.0)
        // Grey50 (#3E3E3E) as 1pt top border
        appearance.shadowColor = UIColor(red: 62.0 / 255.0, green: 62.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
                title: "Home",
                subtitle: viewModel.homeStationDisplayName,
                time: viewModel.homeArrivalTimeText,
                iconColor: Color(red: 1.0, green: 0.689, blue: 0.689),
                iconName: "house.fill"
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
    return MainView(viewModel: vm, onChangeSettings: { print("Change settings") })
}
