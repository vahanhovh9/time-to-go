import Foundation
import Combine

@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - Published state

    @Published var commuteResult: CommuteResult?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let calculationService: CommuteCalculationService
    private(set) var settings: UserSettings

    // MARK: - Init

    init(settings: UserSettings) {
        self.settings = settings
        self.calculationService = CommuteCalculationService()
    }

    init(settings: UserSettings, calculationService: CommuteCalculationService) {
        self.settings = settings
        self.calculationService = calculationService
    }

    // MARK: - Actions

    func loadCommute() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                commuteResult = try await calculationService.calculate(for: settings)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func updateSettings(_ newSettings: UserSettings) {
        settings = newSettings
        settings.save()
        loadCommute()
    }

    // MARK: - Formatted display values

    var leaveHomeTimeText: String {
        guard let result = commuteResult else { return "--:--" }
        return timeFormatter.string(from: result.leaveHomeTime)
    }

    var dayLabelText: String {
        commuteResult?.dayLabel ?? "Today at"
    }

    var serviceStatusText: String {
        commuteResult?.serviceStatus.displayText ?? "Service status: Checking…"
    }

    var trainDepartureText: String {
        guard let result = commuteResult else { return "--:--" }
        return timeFormatter.string(from: result.trainDepartureAtHomeStation)
    }

    var trainArrivalText: String {
        guard let result = commuteResult else { return "--:--" }
        return timeFormatter.string(from: result.trainArrivalAtOfficeStation)
    }

    /// The user's desired arrival time (shown in the Work row of InfoCard per spec §9).
    var userArrivalTimeText: String {
        timeFormatter.string(from: settings.arrivalTime)
    }

    var journeyDurationText: String {
        guard let result = commuteResult else { return "-- min" }
        return "\(result.journeyDurationMinutes) min"
    }

    var numberOfStopsText: String {
        guard let result = commuteResult else { return "-- stops" }
        return "\(result.numberOfStops) stops"
    }

    var homeStationDisplayName: String { cleanStationName(settings.homeStationName) }
    var officeStationDisplayName: String { cleanStationName(settings.officeStationName) }

    private func cleanStationName(_ name: String) -> String {
        name
            .replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
            .replacingOccurrences(of: " Station", with: "")
    }

    // MARK: - Private

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
}
