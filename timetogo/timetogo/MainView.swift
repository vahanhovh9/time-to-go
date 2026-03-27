import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    var onChangeSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .center, spacing: 32) {
                    OnboardingHeader(
                        step: nil,
                        totalSteps: nil,
                        title: "Leave home at"
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 48)

                    TimeDisplay(day: viewModel.dayLabelText, time: viewModel.leaveHomeTimeText)
                        .padding(.horizontal, 24)

                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text(viewModel.serviceStatusText)
                                .bodySmallStyle()
                                .foregroundColor(Color.black)
                        }
                    }
                    // VStack spacing is 32pt; −8pt yields 24pt above service status / loading.
                    .padding(.top, -8)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .labelStyle()
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    InfoCard(items: infoItems)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
            }

            CustomButton(title: "Change your settings", style: .outline) {
                onChangeSettings()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color.yellow
                Image("bg-main")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        )
        .onAppear {
            viewModel.loadCommute()
        }
    }

    // MARK: - InfoCard items built from real viewModel data

    private var infoItems: [InfoItemData] {
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
}

#Preview {
    let settings = UserSettings()
    let vm = MainViewModel(
        settings: settings,
        calculationService: CommuteCalculationService(tflService: MockTFLService())
    )
    return MainView(viewModel: vm, onChangeSettings: { print("Change settings") })
}
