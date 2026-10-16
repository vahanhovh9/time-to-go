import Foundation

// MARK: - Schedule errors

nonisolated enum ScheduleError: LocalizedError {
    case directionUnknown
    case noMatchingPlatformData(String)

    var errorDescription: String? {
        switch self {
        case .directionUnknown:
            return "Schedule unavailable — we don't recognise this route yet. Try refreshing your commute or updating your stations in Settings."
        case .noMatchingPlatformData(let dir):
            return "TFL did not return \(dir) platform data for this stop."
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

        let routes = try await routeSequences(for: context.lineId)
        guard let direction = Self.direction(from: context.homeStopId, to: context.destinationStopId, routes: routes) else {
            throw ScheduleError.directionUnknown
        }

        // TfL tags each arrival "inbound"/"outbound" (same sense as Route/Sequence/outbound).
        // When the tag is missing, infer it from where the train terminates.
        let directionFiltered = future.filter { arrival in
            if let tagged = arrival.direction?.lowercased(), !tagged.isEmpty { return tagged == direction }
            guard let terminus = arrival.destinationNaptanId else { return false }
            return Self.direction(from: context.stopId, to: terminus, routes: routes) == direction
        }

        if directionFiltered.isEmpty && !future.isEmpty {
            throw ScheduleError.noMatchingPlatformData(direction)
        }

        return directionFiltered
            .compactMap { arrival -> ScheduleEntry? in
                guard let date = Self.parseDate(arrival.expectedArrival) else { return nil }
                let minutes = max(0, Int(date.timeIntervalSince(now) / 60))
                return ScheduleEntry(
                    id: arrival.id,
                    lineName: arrival.lineName,
                    platformName: arrival.platformName,
                    destinationName: Self.cleanName(arrival.destinationName ?? ""),
                    towards: arrival.towards ?? "",
                    expectedArrival: date,
                    minutesUntilArrival: minutes
                )
            }
            .sorted { $0.expectedArrival < $1.expectedArrival }
            .prefix(10)
            .map { $0 }
    }

    // MARK: - Direction resolution

    /// Route orders per line, fetched once per app session (they change rarely).
    nonisolated(unsafe) private static var routeCache: [String: [[String]]] = [:]
    private static let cacheLock = NSLock()

    private func routeSequences(for lineId: String) async throws -> [[String]] {
        if let cached = Self.cacheLock.withLock({ Self.routeCache[lineId] }) { return cached }
        let routes = try await tflService.fetchRouteSequences(lineId: lineId)
        Self.cacheLock.withLock { Self.routeCache[lineId] = routes }
        return routes
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
