import Foundation

// MARK: - Schedule errors

nonisolated enum ScheduleError: LocalizedError {
    case directionUnknown

    var errorDescription: String? {
        switch self {
        case .directionUnknown:
            return "Schedule unavailable — we don't recognise this route yet. Try refreshing your commute or updating your stations in Settings."
        }
    }
}

// MARK: - Service

nonisolated final class ScheduleReviewService: @unchecked Sendable {

    private let tflService: TFLServiceProtocol

    init(tflService: TFLServiceProtocol = TFLService()) {
        self.tflService = tflService
    }

    // MARK: - Public

    func fetchSchedule(context: ScheduleReviewContext) async throws -> [ScheduleEntry] {
        // /Line/{lineId}/Arrivals/{stopId} — server-filtered by line
        let arrivals = try await tflService.fetchLineArrivals(lineId: context.lineId, stopId: context.stopId)
        let now = Date()

        let future = arrivals.filter { arrival in
            guard let date = Self.parseDate(arrival.expectedArrival) else { return false }
            return date > now
        }

        let line = try await routeSequence(for: context.lineId)
        let routes = line.orderedLineRoutes.map(\.naptanIds)
        guard let direction = Self.direction(from: context.homeStopId, to: context.destinationStopId, routes: routes) else {
            throw ScheduleError.directionUnknown
        }
        let stationNames = Dictionary(line.stops.map { ($0.id, Self.cleanName($0.name)) }, uniquingKeysWith: { first, _ in first })

        // Keep only trains that call at the destination. Going the right way isn't enough on
        // branching lines: from Old Street, northbound Edgware trains never reach Totteridge,
        // and from Totteridge, southbound "via CX" trains never reach Old Street.
        let reachesDestination = future.filter { arrival in
            guard let terminus = arrival.destinationNaptanId, !terminus.isEmpty else {
                // No terminus to check the branch against: going the right way is all we know.
                return arrival.direction?.lowercased() == direction
            }
            let via = Self.viaStations(in: arrival.towards, names: stationNames)
            return routes.contains { route in
                Self.route(route, takes: context.stopId, to: context.destinationStopId, before: terminus)
                    && (via.isEmpty || !via.isDisjoint(with: route))
            }
        }

        let live = reachesDestination.compactMap { arrival -> ScheduleEntry? in
            guard let date = Self.parseDate(arrival.expectedArrival) else { return nil }
            return ScheduleEntry(
                id: arrival.id,
                lineName: arrival.lineName,
                platformName: arrival.platformName,
                destinationName: Self.cleanName(arrival.destinationName ?? ""),
                towards: arrival.towards ?? "",
                expectedArrival: date,
                minutesUntilArrival: Self.minutes(until: date, from: now)
            )
        }

        // TfL only predicts trains that are already moving, so near the start of a line
        // (Totteridge, two stops from High Barnet) the live feed misses trains still waiting
        // at the terminus. Fill in after the last live train from the timetable. A timetable
        // failure just leaves the live trains.
        let lastLive = live.map(\.expectedArrival).max()
        let platform = Self.mostCommon(future.filter { $0.direction?.lowercased() == direction }.map(\.platformName))
        let scheduled = ((try? await scheduledDepartures(context: context, direction: direction, now: now)) ?? [])
            .filter { lastLive == nil || $0.date > lastLive!.addingTimeInterval(60) }
            .map { departure in
                ScheduleEntry(
                    id: "scheduled-\(departure.date.timeIntervalSince1970)",
                    lineName: "",
                    platformName: platform.map { "Scheduled · \($0)" } ?? "Scheduled",
                    destinationName: departure.terminus,
                    towards: "",
                    expectedArrival: departure.date,
                    minutesUntilArrival: Self.minutes(until: departure.date, from: now),
                    isScheduled: true
                )
            }

        return (live + scheduled)
            .sorted { $0.expectedArrival < $1.expectedArrival }
            .prefix(10)
            .map { $0 }
    }

    // MARK: - Timetable

    /// How far ahead to show scheduled trains.
    private static let timetableWindow: TimeInterval = 60 * 60

    /// Timetables per line, stop and direction, fetched once per app session.
    nonisolated(unsafe) private static var timetableCache: [String: TFLTimetable] = [:]

    /// Timetabled departures in the next hour that call at the destination.
    private func scheduledDepartures(
        context: ScheduleReviewContext,
        direction: String,
        now: Date
    ) async throws -> [(date: Date, terminus: String)] {
        let key = "\(context.lineId)|\(context.stopId)|\(direction)"
        let timetable: TFLTimetable
        if let cached = Self.cacheLock.withLock({ Self.timetableCache[key] }) {
            timetable = cached
        } else {
            timetable = try await tflService.fetchTimetable(lineId: context.lineId, stopId: context.stopId, direction: direction)
            Self.cacheLock.withLock { Self.timetableCache[key] = timetable }
        }

        let names = Dictionary(timetable.stops.map { ($0.id, Self.cleanName($0.name)) }, uniquingKeysWith: { first, _ in first })
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        let today = calendar.startOfDay(for: now)
        let end = now.addingTimeInterval(Self.timetableWindow)

        var departures: [(date: Date, terminus: String)] = []
        for route in timetable.routes {
            let patterns = Dictionary(route.stationIntervals.map { (Int($0.id) ?? -1, $0.intervals.map(\.stopId)) },
                                      uniquingKeysWith: { first, _ in first })
            // A service day runs past midnight (hours 24+), so yesterday's can still be running.
            for offset in [-1, 0] {
                guard let serviceDay = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
                let weekday = calendar.component(.weekday, from: serviceDay)
                guard let schedule = route.schedules.first(where: { Self.weekdays(coveredBy: $0.name).contains(weekday) }) else { continue }

                for journey in schedule.knownJourneys {
                    guard let hour = Int(journey.hour), let minute = Int(journey.minute),
                          let stops = patterns[journey.intervalId],
                          stops.contains(context.destinationStopId),
                          let date = calendar.date(byAdding: .minute, value: hour * 60 + minute, to: serviceDay),
                          date > now, date <= end else { continue }
                    let terminus = stops.last.flatMap { names[$0] } ?? ""
                    departures.append((date, terminus))
                }
            }
        }
        return departures
    }

    /// Weekdays (1 = Sunday … 7 = Saturday) a schedule covers: "Monday - Thursday" → 2…5,
    /// "Friday" → 6, "Saturday (also Good Friday)" → 7. Bank holidays aren't handled.
    private static func weekdays(coveredBy name: String) -> Set<Int> {
        let days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let text = (name.lowercased().components(separatedBy: "(").first ?? "")
        let mentioned = days.indices
            .compactMap { i in text.range(of: days[i]).map { (position: $0.lowerBound, weekday: i + 1) } }
            .sorted { $0.position < $1.position }
            .map(\.weekday)
        guard mentioned.count == 2, text.contains("-") else { return Set(mentioned) }
        var range: Set<Int> = []
        var day = mentioned[0]
        while true {
            range.insert(day)
            if day == mentioned[1] { break }
            day = day % 7 + 1
        }
        return range
    }

    private static func minutes(until date: Date, from now: Date) -> Int {
        max(0, Int(date.timeIntervalSince(now) / 60))
    }

    private static func mostCommon(_ values: [String]) -> String? {
        let counts = Dictionary(values.filter { !$0.isEmpty }.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.max { $0.value < $1.value }?.key
    }

    // MARK: - Direction resolution

    /// Route orders per line, fetched once per app session (they change rarely).
    nonisolated(unsafe) private static var routeCache: [String: TFLRouteSequence] = [:]
    private static let cacheLock = NSLock()

    private func routeSequence(for lineId: String) async throws -> TFLRouteSequence {
        if let cached = Self.cacheLock.withLock({ Self.routeCache[lineId] }) { return cached }
        let sequence = try await tflService.fetchRouteSequences(lineId: lineId)
        Self.cacheLock.withLock { Self.routeCache[lineId] = sequence }
        return sequence
    }

    /// "outbound" when `to` comes after `from` on a branch that serves both, else "inbound".
    /// nil when no single branch has both stations.
    private static func direction(from: String, to: String, routes: [[String]]) -> String? {
        for route in routes {
            if let a = route.firstIndex(of: from), let b = route.firstIndex(of: to), a != b {
                return a < b ? "outbound" : "inbound"
            }
        }
        return nil
    }

    /// True when a train on `route` terminating at `terminus` calls at `from` and then at `to`,
    /// in either direction (routes are listed outbound).
    private static func route(_ route: [String], takes from: String, to: String, before terminus: String) -> Bool {
        guard let a = route.firstIndex(of: from),
              let b = route.firstIndex(of: to),
              let t = route.firstIndex(of: terminus),
              a != b else { return false }
        return a < b ? b <= t : t <= b
    }

    /// Stations named after "via" in a train's heading ("Morden via Bank", "Battersea via CX").
    /// Empty when there's no "via" or it doesn't name a station (Piccadilly's "via T4 Loop").
    private static func viaStations(in towards: String?, names: [String: String]) -> Set<String> {
        guard let towards, let range = towards.range(of: " via ", options: .caseInsensitive) else { return [] }
        var place = towards[range.upperBound...].trimmingCharacters(in: .whitespaces)
        if place.caseInsensitiveCompare("CX") == .orderedSame { place = "Charing Cross" }
        return Set(names.filter { $0.value.caseInsensitiveCompare(place) == .orderedSame }.keys)
    }

    // MARK: - Helpers

    private static func parseDate(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    private static func cleanName(_ name: String) -> String {
        name
            .replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
            .replacingOccurrences(of: " Station", with: "")
    }
}
