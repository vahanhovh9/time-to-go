import Foundation
import Combine

@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - Published state

    @Published var commuteResult: CommuteResult?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var outboundResult: CommuteResult?
    @Published var isLoadingOutbound: Bool = false
    @Published var outboundErrorMessage: String?

    /// Populated after every inbound load — read by DevMenu to show effective request values.
    @Published var journeyDebugInfo: String?

    // MARK: - Dependencies

    private let calculationService: CommuteCalculationService
    @Published private(set) var settings: UserSettings

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

    /// Load commute result.
    ///
    /// - Parameter forceRefresh: When `true`, bypasses the active-cache lock and forces a
    ///   fresh API call. Use for:
    ///     • Notification tap when no active cache exists (§11.8 Case B).
    ///     • Manual pull-to-refresh.
    ///     • Date or settings change (§11.9).
    ///   When `false` (default), the active-cache rule is respected per §11.7.
    func loadCommute(forceRefresh: Bool = false) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                commuteResult = try await calculationService.calculate(
                    for: settings,
                    forceRefresh: forceRefresh
                )
                journeyDebugInfo = buildJourneyDebugInfo()
            } catch {
                errorMessage = error.localizedDescription
                journeyDebugInfo = buildJourneyDebugInfo(error: error)
            }
            isLoading = false
        }
    }

    func loadOutbound(forceRefresh: Bool = false) {
        guard settings.outboundEnabled else { return }
        Task {
            isLoadingOutbound = true
            outboundErrorMessage = nil
            do {
                outboundResult = try await calculationService.calculateOutbound(
                    for: settings,
                    forceRefresh: forceRefresh
                )
            } catch {
                outboundErrorMessage = error.localizedDescription
            }
            isLoadingOutbound = false
        }
    }

    func updateSettings(_ newSettings: UserSettings) {
        settings = newSettings
        settings.save()
        loadCommute(forceRefresh: true)
        loadOutbound(forceRefresh: true)
    }

    /// Awaitable versions for pull-to-refresh — keeps the spinner visible until the request completes.
    func refreshInbound() async {
        isLoading = true
        errorMessage = nil
        do {
            commuteResult = try await calculationService.calculate(for: settings, forceRefresh: true)
            journeyDebugInfo = buildJourneyDebugInfo()
        } catch {
            errorMessage = error.localizedDescription
            journeyDebugInfo = buildJourneyDebugInfo(error: error)
        }
        isLoading = false
    }

    func refreshOutbound() async {
        guard settings.outboundEnabled else { return }
        isLoadingOutbound = true
        outboundErrorMessage = nil
        do {
            outboundResult = try await calculationService.calculateOutbound(for: settings, forceRefresh: true)
        } catch {
            outboundErrorMessage = error.localizedDescription
        }
        isLoadingOutbound = false
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

    // MARK: - Outbound display values (office → home)

    var leaveOfficeTimeText: String {
        guard let result = outboundResult else { return "--:--" }
        return timeFormatter.string(from: result.leaveHomeTime)
    }

    var outboundServiceStatusText: String {
        outboundResult?.serviceStatus.displayText ?? "Service status: Checking…"
    }

    var outboundTrainDepartureText: String {
        guard let result = outboundResult else { return "--:--" }
        return timeFormatter.string(from: result.trainDepartureAtHomeStation)
    }

    var homeArrivalTimeText: String {
        timeFormatter.string(from: settings.outboundArrivalTime)
    }

    var outboundJourneyDurationText: String {
        guard let result = outboundResult else { return "-- min" }
        return "\(result.journeyDurationMinutes) min"
    }

    var outboundNumberOfStopsText: String {
        guard let result = outboundResult else { return "-- stops" }
        return "\(result.numberOfStops) stops"
    }

    // MARK: -

    /// §11.6: True when the displayed result was reconstructed from cache (stale indicator).
    var isShowingCachedResult: Bool { commuteResult?.isFromCache ?? false }

    var homeStationDisplayName: String { cleanStationName(settings.homeStationName) }
    var officeStationDisplayName: String { cleanStationName(settings.officeStationName) }
    var outboundDestinationDisplayName: String { cleanStationName(settings.effectiveOutboundDestinationName) }

    // MARK: - Schedule review contexts

    var inboundScheduleContext: ScheduleReviewContext? {
        guard commuteResult != nil,
              !settings.homeStationId.isEmpty,
              !settings.officeStationId.isEmpty,
              !settings.homeLineId.isEmpty else { return nil }
        return ScheduleReviewContext(
            stopId: settings.homeStationId,
            lineId: settings.homeLineId,
            homeStopId: settings.homeStationId,
            destinationStopId: settings.officeStationId,
            destinationStationName: officeStationDisplayName
        )
    }

    var outboundScheduleContext: ScheduleReviewContext? {
        guard outboundResult != nil,
              !settings.officeStationId.isEmpty,
              !settings.homeStationId.isEmpty,
              !settings.homeLineId.isEmpty else { return nil }
        return ScheduleReviewContext(
            stopId: settings.officeStationId,
            lineId: settings.homeLineId,
            homeStopId: settings.officeStationId,
            destinationStopId: settings.homeStationId,
            destinationStationName: homeStationDisplayName
        )
    }

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

    private func buildJourneyDebugInfo(error: Error? = nil) -> String {
        var lines: [String] = []
        lines.append("─── Stored IDs ───")
        lines.append("Home:   \(settings.homeStationId.isEmpty ? "(empty)" : settings.homeStationId)")
        lines.append("Office: \(settings.officeStationId.isEmpty ? "(empty)" : settings.officeStationId)")
        lines.append("IsTube? Home=\(settings.homeStationId.hasPrefix("940GZZLU"))  Office=\(settings.officeStationId.hasPrefix("940GZZLU"))")
        lines.append("─── TFL Request ───")
        lines.append("Disambig ran: \(TFLService.debugDisambiguated)")
        if TFLService.debugDisambiguated {
            lines.append("Resolved from: \(TFLService.debugResolvedFrom.isEmpty ? "unchanged" : TFLService.debugResolvedFrom)")
            lines.append("Resolved to:   \(TFLService.debugResolvedTo.isEmpty   ? "unchanged" : TFLService.debugResolvedTo)")
        }
        lines.append("Journey count: \(TFLService.debugJourneyCount)")
        if !TFLService.debugJourneyDurations.isEmpty {
            lines.append("Durations: \(TFLService.debugJourneyDurations.map { "\($0)m" }.joined(separator: ", "))")
        }
        lines.append("─── Result ───")
        if let e = error {
            lines.append("Error: \(e.localizedDescription)")
        } else if let r = commuteResult {
            lines.append("Selected: \(r.journeyDurationMinutes) min")
            lines.append("Depart: \(timeFormatter.string(from: r.trainDepartureAtHomeStation))")
            lines.append("Arrive: \(timeFormatter.string(from: r.trainArrivalAtOfficeStation))")
            lines.append("Cached: \(r.isFromCache)")
        } else {
            lines.append("(no result)")
        }
        return lines.joined(separator: "\n")
    }
}
