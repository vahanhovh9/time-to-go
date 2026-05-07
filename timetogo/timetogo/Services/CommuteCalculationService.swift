import Foundation

/// Orchestrates the full commute calculation pipeline (§7):
///   1. Respect §11.6 active-cache rule — skip API if an active result exists for today.
///   2. Work backwards from desired arrival time to derive the TFL query target.
///   3. Query TFL for the latest viable journey.
///   4. Subtract walking time + safety buffer → leaveHomeTime.
///   5. Cache the result (§11.4).
///   6. Fall back to stale cache if TFL fails (§11.5).
final class CommuteCalculationService {

    private let safetyBufferMinutes: Int = 2

    private let tflService:   TFLServiceProtocol
    private let cacheManager: CommuteCacheManager

    init(
        tflService:   TFLServiceProtocol   = TFLService(),
        cacheManager: CommuteCacheManager  = CommuteCacheManager()
    ) {
        self.tflService   = tflService
        self.cacheManager = cacheManager
    }

    // MARK: - Public API

    /// Calculate the commute result for the user's next office day.
    ///
    /// - Parameter forceRefresh: When `true`, bypasses the active-cache rule.
    ///   Use for manual refresh, date changes, or settings changes (§11.7).
    func calculate(for settings: UserSettings, forceRefresh: Bool = false) async throws -> CommuteResult {
        let commuteDate = nextCommuteDate(from: settings)

        // §11.6 — Return active cache immediately unless a refresh is forced.
        if !forceRefresh, cacheManager.hasActiveResult(for: commuteDate) {
            if let cached = cacheManager.load(for: commuteDate) {
                return CommuteResult(from: cached)
            }
        }

        do {
            let result = try await fetchFreshResult(for: settings, on: commuteDate)
            cacheManager.save(result, for: commuteDate)   // §11.4
            return result
        } catch {
            // §11.5 — API failed: use any same-day cache entry as fallback.
            if let fallback = cacheManager.fallback(for: commuteDate) {
                let note = fallback.serviceStatusText + " (Using last available data)"
                return CommuteResult(
                    leaveHomeTime:               fallback.leaveHomeTime,
                    trainDepartureAtHomeStation: fallback.trainDepartureAtHomeStation,
                    trainArrivalAtOfficeStation: fallback.trainArrivalAtOfficeStation,
                    journeyDurationMinutes:      fallback.journeyDurationMinutes,
                    numberOfStops:               fallback.numberOfStops,
                    serviceStatus:               .unknown(note),
                    dayLabel:                    fallback.dayLabel,
                    isFromCache:                 true
                )
            }
            throw error   // No cache available — surface the error.
        }
    }

    /// Calculate the outbound commute result (office → destination) per §12.9.
    func calculateOutbound(for settings: UserSettings, forceRefresh: Bool = false) async throws -> CommuteResult {
        guard settings.outboundEnabled,
              !settings.officeStationId.isEmpty,
              !settings.outboundDestinationStationId.isEmpty else {
            throw TFLError.noJourneyFound
        }

        let commuteDate = nextCommuteDate(from: settings)

        let trainArrivalTarget = applyTime(settings.outboundArrivalTime, to: commuteDate)
            .addingTimeInterval(TimeInterval(-settings.outboundWalkingTimeFromStation * 60))

        let journey = try await tflService.fetchJourney(
            from:       settings.officeStationId,
            to:         settings.outboundDestinationStationId,
            arrivingBy: trainArrivalTarget
        )

        let trainDeparture = Self.parseTFLDate(journey.startDateTime)   ?? trainArrivalTarget
        let trainArrival   = Self.parseTFLDate(journey.arrivalDateTime) ?? trainArrivalTarget
        let numberOfStops  = journey.legs.reduce(0) { $0 + ($1.path?.stopPoints.count ?? 0) }

        let leaveOfficeTime = trainDeparture
            .addingTimeInterval(TimeInterval(-(settings.walkingMinutesToOffice + safetyBufferMinutes) * 60))

        let lineIds      = settings.outboundLineIds.filter { !$0.isEmpty }
        let lineStatuses = try await tflService.fetchLineStatus(for: lineIds)

        return CommuteResult(
            leaveHomeTime:               leaveOfficeTime,
            trainDepartureAtHomeStation: trainDeparture,
            trainArrivalAtOfficeStation: trainArrival,
            journeyDurationMinutes:      journey.durationMinutes,
            numberOfStops:               numberOfStops,
            serviceStatus:               resolveServiceStatus(from: lineStatuses),
            dayLabel:                    dayLabel(for: commuteDate)
        )
    }

    // MARK: - Helpers

    /// Returns the soonest upcoming date that falls on one of the user's office days
    /// AND whose commute window has not yet passed.
    ///
    /// "Passed" means `now >= arrivalTime` for that day — the user has already
    /// arrived (or should have). Example: it is Thursday 21:08 and arrivalTime is 09:00,
    /// so Thursday's slot is gone and the function returns the next office day instead.
    func nextCommuteDate(from settings: UserSettings) -> Date {
        let calendar        = Calendar.current
        let now             = Date()
        let todayWeekday    = calendar.component(.weekday, from: now)
        let officeDayValues = Set(settings.officeDays.map { $0.rawValue })
        guard !officeDayValues.isEmpty else { return now }

        for offset in 0...13 {   // scan up to two weeks to be safe
            let weekdayCandidate = ((todayWeekday - 1 + offset) % 7) + 1
            guard officeDayValues.contains(weekdayCandidate) else { continue }

            guard let candidateDay = calendar.date(byAdding: .day, value: offset, to: now) else { continue }

            // Build the arrival datetime for this candidate day.
            let arrivalOnDay = applyTime(settings.arrivalTime, to: candidateDay)

            // If now is before arrivalTime on this day, the commute window is still open.
            if now < arrivalOnDay {
                return candidateDay
            }
            // Otherwise today's window has passed — continue to the next office day.
        }

        // Fallback: return tomorrow (should never be reached with valid settings).
        return calendar.date(byAdding: .day, value: 1, to: now) ?? now
    }

    func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date)    { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return "Upcoming \(formatter.string(from: date))"
    }

    // MARK: - Private

    private func fetchFreshResult(for settings: UserSettings, on commuteDate: Date) async throws -> CommuteResult {
        // desiredTrainArrival = userArrivalTime − walkToOffice
        let trainArrivalTarget = applyTime(settings.arrivalTime, to: commuteDate)
            .addingTimeInterval(TimeInterval(-settings.walkingMinutesToOffice * 60))

        let journey = try await tflService.fetchJourney(
            from:      settings.homeStationId,
            to:        settings.officeStationId,
            arrivingBy: trainArrivalTarget
        )

        let trainDeparture = Self.parseTFLDate(journey.startDateTime)  ?? trainArrivalTarget
        let trainArrival   = Self.parseTFLDate(journey.arrivalDateTime) ?? trainArrivalTarget

        let numberOfStops = journey.legs.reduce(0) { $0 + ($1.path?.stopPoints.count ?? 0) }

        // leaveHomeTime = trainDeparture − walkToStation − safetyBuffer
        let leaveHomeTime = trainDeparture
            .addingTimeInterval(TimeInterval(-(settings.walkingMinutesToStation + safetyBufferMinutes) * 60))

        let lineIds     = [settings.homeLineId, settings.officeLineId].filter { !$0.isEmpty }
        let lineStatuses = try await tflService.fetchLineStatus(for: lineIds)

        return CommuteResult(
            leaveHomeTime:               leaveHomeTime,
            trainDepartureAtHomeStation: trainDeparture,
            trainArrivalAtOfficeStation: trainArrival,
            journeyDurationMinutes:      journey.durationMinutes,
            numberOfStops:               numberOfStops,
            serviceStatus:               resolveServiceStatus(from: lineStatuses),
            dayLabel:                    dayLabel(for: commuteDate)
        )
    }

    /// Parses TFL date strings, which typically omit timezone:
    /// e.g. "2026-01-23T08:19:00" — treated as Europe/London local time.
    private static func parseTFLDate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: string) { return date }

        let formatter = DateFormatter()
        formatter.locale   = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/London")
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZ"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }

    /// Copies the hour/minute from `time` onto the calendar `date`.
    private func applyTime(_ time: Date, to date: Date) -> Date {
        let cal        = Calendar.current
        let components = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(
            bySettingHour: components.hour   ?? 9,
            minute:        components.minute ?? 0,
            second:        0,
            of:            date
        ) ?? date
    }

    private func resolveServiceStatus(from lines: [TFLLine]) -> ServiceStatus {
        for line in lines {
            let s = (line.lineStatuses?.first?.statusSeverityDescription ?? "").lowercased()
            if s.contains("severe") { return .severeDelays(line.serviceStatus) }
        }
        for line in lines {
            let s = (line.lineStatuses?.first?.statusSeverityDescription ?? "").lowercased()
            if s.contains("minor") || s.contains("delay") { return .minorDelays(line.serviceStatus) }
        }
        return .goodService
    }
}
