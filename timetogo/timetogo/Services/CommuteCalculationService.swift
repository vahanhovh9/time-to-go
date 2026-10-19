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

    /// Today's (or the next office day's) saved result, if it's still fresh — shown instantly
    /// on launch while `calculate` fetches a new one.
    func cachedResult(for settings: UserSettings) -> CommuteResult? {
        cacheManager.load(for: nextCommuteDate(from: settings)).map { CommuteResult(from: $0) }
    }

    /// Drops the saved result, e.g. after the stations or times change.
    func clearCache() {
        cacheManager.clear()
    }

    /// Calculate the commute result for the user's next office day.
    ///
    /// - Parameter forceRefresh: When `true`, errors are surfaced instead of falling back
    ///   to stale cache. Use for manual refresh, date changes, or settings changes.
    func calculate(for settings: UserSettings, forceRefresh: Bool = false) async throws -> CommuteResult {
        let commuteDate = nextCommuteDate(from: settings)

        do {
            let result = try await fetchFreshResult(for: settings, on: commuteDate)
            cacheManager.save(result, for: commuteDate)   // §11.4
            return result
        } catch {
            // §11.5 — During a forced refresh (settings change / manual pull) always surface
            // the real error so the user sees what's wrong instead of silently seeing stale data.
            if !forceRefresh, let fallback = cacheManager.fallback(for: commuteDate) {
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
            throw error
        }
    }

    /// Calculate the outbound commute result (office → destination) per §12.9.
    func calculateOutbound(for settings: UserSettings, forceRefresh: Bool = false) async throws -> CommuteResult {
        let destinationId = settings.effectiveOutboundDestinationId
        guard settings.outboundEnabled,
              !settings.officeStationId.isEmpty,
              !destinationId.isEmpty else {
            throw TFLError.noJourneyFound
        }

        let commuteDate = nextCommuteDate(from: settings)

        // Invariant guard: both IDs must be canonical tube NaPTANs before hitting the API.
        for (label, id) in [("office", settings.officeStationId), ("outbound-destination", destinationId)]
        where !id.hasPrefix("940GZZ") {
            print("[CommuteCalculation] WARNING: non-canonical \(label) station ID: \(id)")
        }

        let trainArrivalTarget = applyTime(settings.outboundArrivalTime, to: commuteDate)
            .addingTimeInterval(TimeInterval(-settings.effectiveOutboundWalkingTime * 60))

        let candidateLines = settings.outboundLineIds.filter { !$0.isEmpty }
        async let statusRequest = (try? await tflService.fetchLineStatus(for: candidateLines)) ?? []

        let journey = try await tflService.fetchJourney(
            from:       settings.officeStationId,
            to:         destinationId,
            arrivingBy: trainArrivalTarget
        )
        let journeyLines = Self.lineIds(of: journey)

        let trainDeparture = Self.parseTFLDate(journey.startDateTime)   ?? trainArrivalTarget
        let trainArrival   = Self.parseTFLDate(journey.arrivalDateTime) ?? trainArrivalTarget
        let numberOfStops  = journey.legs.reduce(0) { $0 + ($1.path?.stopPoints.count ?? 0) }

        let leaveOfficeTime = trainDeparture
            .addingTimeInterval(TimeInterval(-(settings.walkingMinutesToOffice + safetyBufferMinutes) * 60))

        let (status, lineById) = await serviceStatus(for: journey, prefetched: await statusRequest)

        return CommuteResult(
            leaveHomeTime:               leaveOfficeTime,
            trainDepartureAtHomeStation: trainDeparture,
            trainArrivalAtOfficeStation: trainArrival,
            journeyDurationMinutes:      journey.durationMinutes,
            numberOfStops:               numberOfStops,
            serviceStatus:               status,
            dayLabel:                    dayLabel(for: commuteDate),
            lineIds:                     journeyLines
        )
        .withFirstTrainExit(Self.firstTrainExit(of: journey))
        .withLegs(Self.journeyLegs(of: journey, lines: lineById))
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
        // Invariant guard: both IDs must be canonical tube NaPTANs before hitting the API.
        for (label, id) in [("home", settings.homeStationId), ("office", settings.officeStationId)]
        where !id.hasPrefix("940GZZ") {
            print("[CommuteCalculation] WARNING: non-canonical \(label) station ID: \(id)")
        }

        // desiredTrainArrival = userArrivalTime − walkToOffice
        let trainArrivalTarget = applyTime(settings.arrivalTime, to: commuteDate)
            .addingTimeInterval(TimeInterval(-settings.walkingMinutesToOffice * 60))

        // Line status doesn't depend on the journey, so request both at once.
        // Status is best-effort: a failing status call must not abort the journey result.
        let candidateLines = Array(Set(settings.homeLineIds + settings.officeLineIds)).filter { !$0.isEmpty }
        async let statusRequest = (try? await tflService.fetchLineStatus(for: candidateLines)) ?? []

        let journey = try await tflService.fetchJourney(
            from:      settings.homeStationId,
            to:        settings.officeStationId,
            arrivingBy: trainArrivalTarget
        )
        let journeyLines = Self.lineIds(of: journey)

        let trainDeparture = Self.parseTFLDate(journey.startDateTime)  ?? trainArrivalTarget
        let trainArrival   = Self.parseTFLDate(journey.arrivalDateTime) ?? trainArrivalTarget

        let numberOfStops = journey.legs.reduce(0) { $0 + ($1.path?.stopPoints.count ?? 0) }

        // leaveHomeTime = trainDeparture − walkToStation − safetyBuffer
        let leaveHomeTime = trainDeparture
            .addingTimeInterval(TimeInterval(-(settings.walkingMinutesToStation + safetyBufferMinutes) * 60))

        let (status, lineById) = await serviceStatus(for: journey, prefetched: await statusRequest)

        return CommuteResult(
            leaveHomeTime:               leaveHomeTime,
            trainDepartureAtHomeStation: trainDeparture,
            trainArrivalAtOfficeStation: trainArrival,
            journeyDurationMinutes:      journey.durationMinutes,
            numberOfStops:               numberOfStops,
            serviceStatus:               status,
            dayLabel:                    dayLabel(for: commuteDate),
            lineIds:                     journeyLines
        )
        .withFirstTrainExit(Self.firstTrainExit(of: journey))
        .withLegs(Self.journeyLegs(of: journey, lines: lineById))
    }

    /// NaPTAN where the first train leg ends.
    private static func firstTrainExit(of journey: TFLJourneyResult) -> String? {
        journey.legs.first(where: { $0.isTrain })?.arrivalPoint.naptanId
    }

    /// Lines used by the journey, in travel order, without repeats.
    private static func lineIds(of journey: TFLJourneyResult) -> [String] {
        var seen = Set<String>()
        return journey.legs.compactMap { leg in
            guard leg.isTrain, let id = leg.lineId, !id.isEmpty, seen.insert(id).inserted else { return nil }
            return id
        }
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

    // MARK: - Service status

    /// Status of the worst line on the route, worded as advice, e.g. "Severe delays on
    /// Thameslink. Leave earlier to catch the Luton train." A later line counts as much as
    /// the first: a delay at the change still makes you late.
    ///
    /// `prefetched` covers the home and office stations' lines (requested alongside the
    /// journey); lines met only at a change, like Thameslink at Kentish Town, are fetched here.
    /// Also returns every fetched line by ID, so the journey page can flag the delayed train.
    private func serviceStatus(
        for journey: TFLJourneyResult,
        prefetched: [TFLLine]
    ) async -> (ServiceStatus, [String: TFLLine]) {
        let legs = journey.legs.filter { $0.isTrain && !($0.lineId ?? "").isEmpty }
        var lines = prefetched
        let missing = Set(legs.compactMap(\.lineId)).subtracting(lines.map(\.id))
        if !missing.isEmpty {
            lines += (try? await tflService.fetchLineStatus(for: Array(missing))) ?? []
        }
        let lineById = Dictionary(lines.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        // (line, how to name it, where the train is heading) for each train in the journey;
        // without legs, fall back to the stations' lines.
        let candidates: [(line: TFLLine, isNamedLine: Bool, heading: String?)] = legs.isEmpty
            ? prefetched.map { ($0, true, nil) }
            : legs.compactMap { leg in
                guard let id = leg.lineId, let line = lineById[id] else { return nil }
                let named = ["tube", "overground"].contains(leg.mode?.id ?? "")
                return (line, named, leg.heading)
            }

        // The worst line decides; on a tie, the earlier one.
        var worst: (line: TFLLine, isNamedLine: Bool, heading: String?, severity: LineSeverity)?
        for candidate in candidates {
            let severity = LineSeverity(candidate.line.serviceStatus)
            if severity > (worst?.severity ?? .good) {
                worst = (candidate.line, candidate.isNamedLine, candidate.heading, severity)
            }
        }
        guard let worst else { return (.goodService, lineById) }

        let lineName = worst.isNamedLine ? "the \(worst.line.name) line" : worst.line.name
        let what = Self.sentenceCase(worst.line.serviceStatus) + " on \(lineName)."
        let advice: String
        switch worst.severity {
        case .disrupted:
            advice = "Check your route before you leave."
        default:
            advice = worst.heading.map { "Leave earlier to catch the \(Self.cleanStationName($0)) train." }
                ?? "Leave earlier."
        }
        let message = "\(what) \(advice)"
        return (worst.severity == .minor ? .minorDelays(message) : .severeDelays(message), lineById)
    }

    // MARK: - Journey legs

    /// Trains and walks for the journey page. Other modes (e.g. a bus replacement) are skipped.
    private static func journeyLegs(of journey: TFLJourneyResult, lines: [String: TFLLine]) -> [JourneyLeg] {
        journey.legs.compactMap { leg in
            guard let departure = leg.departureTime.flatMap({ parseTFLDate($0) }),
                  let arrival = leg.arrivalTime.flatMap({ parseTFLDate($0) }) else { return nil }
            let from = cleanStationName(leg.departurePoint.commonName)
            let to = cleanStationName(leg.arrivalPoint.commonName)

            if leg.isTrain {
                let line = leg.lineId.flatMap { lines[$0] }
                let name = leg.routeOptions?.first?.name ?? line?.name
                let isNamedLine = ["tube", "overground"].contains(leg.mode?.id ?? "")
                let status = line.map(\.serviceStatus).flatMap { LineSeverity($0) == .good ? nil : sentenceCase($0) }
                return JourneyLeg(
                    kind: .train,
                    from: from,
                    to: to,
                    departure: departure,
                    arrival: arrival,
                    lineId: leg.lineId,
                    lineName: name.map { isNamedLine ? "\($0) line" : $0 },
                    heading: leg.heading.map { $0.tflHeading },
                    stops: leg.path?.stopPoints.map { cleanStationName($0.name) } ?? [],
                    statusText: status
                )
            }
            if leg.mode?.id == "walking" {
                return JourneyLeg(kind: .walk, from: from, to: to, departure: departure, arrival: arrival)
            }
            return nil
        }
    }

    /// "Part Suspended" → "Part suspended".
    private static func sentenceCase(_ text: String) -> String {
        let lower = text.lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }

    /// "Luton Rail Station" → "Luton".
    private static func cleanStationName(_ name: String) -> String { name.tflStationName }
}

/// How bad a TfL line status is, from its severity description.
private enum LineSeverity: Int, Comparable {
    case good, minor, severe, disrupted

    init(_ description: String) {
        let s = description.lowercased()
        if ["suspended", "closed", "closure", "not running", "no service"].contains(where: s.contains) {
            self = .disrupted
        } else if s.contains("severe") || s.contains("serious") {
            self = .severe
        } else if ["minor", "moderate", "delay", "reduced", "special", "frequency", "diverted", "bus service", "issues"]
                    .contains(where: s.contains) {
            self = .minor
        } else {
            self = .good   // Good Service, No Issues, Information, Exit Only, …
        }
    }

    static func < (a: LineSeverity, b: LineSeverity) -> Bool { a.rawValue < b.rawValue }
}
