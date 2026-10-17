import Foundation

// MARK: - Lines

nonisolated struct TFLLine: Identifiable, Codable, Hashable, CustomStringConvertible {
    let id: String
    let name: String
    let lineStatuses: [TFLLineStatus]?

    static let placeholder = TFLLine(id: "", name: "Choose", lineStatuses: nil)

    var description: String { name }

    var serviceStatus: String {
        lineStatuses?.first?.statusSeverityDescription ?? "Unknown"
    }

    static func == (lhs: TFLLine, rhs: TFLLine) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

nonisolated struct TFLLineStatus: Codable {
    let statusSeverityDescription: String
}

// MARK: - Line Reference (lightweight, used in station search results)

nonisolated struct TFLLineRef: Codable, Hashable {
    let id: String
    let name: String

    // Defensive: TFL occasionally returns line entries with missing id or name
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id   = (try? c.decode(String.self, forKey: .id))   ?? ""
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    enum CodingKeys: String, CodingKey { case id, name }
}

// MARK: - Stop Points (Stations)

nonisolated struct TFLStopPoint: Identifiable, Codable, Hashable, CustomStringConvertible {
    let naptanId: String
    let commonName: String
    var lines: [TFLLineRef]

    static let placeholder = TFLStopPoint(naptanId: "", commonName: "Choose", lines: [])

    var id: String { naptanId }

    var displayName: String {
        commonName
            .replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
            .replacingOccurrences(of: " Station", with: "")
    }

    var description: String { displayName }

    /// "Jubilee Line" / "Jubilee, Metropolitan" / "Jubilee, Metropolitan +3 lines"
    var lineDisplayText: String {
        switch lines.count {
        case 0: return ""
        case 1: return "\(lines[0].name) Line"
        case 2: return lines.map { $0.name }.joined(separator: ", ")
        default:
            let first2 = lines.prefix(2).map { $0.name }.joined(separator: ", ")
            return "\(first2) +\(lines.count - 2) lines"
        }
    }

    init(naptanId: String, commonName: String, lines: [TFLLineRef] = []) {
        self.naptanId = naptanId
        self.commonName = commonName
        self.lines = lines
    }

    // Custom decoder so `lines` gracefully defaults to [] when absent
    // (stations fetched via /Line/{id}/StopPoints don't carry line info)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        naptanId   = try c.decode(String.self, forKey: .naptanId)
        commonName = try c.decode(String.self, forKey: .commonName)
        lines      = (try? c.decode([TFLLineRef].self, forKey: .lines)) ?? []
    }

    static func == (lhs: TFLStopPoint, rhs: TFLStopPoint) -> Bool { lhs.naptanId == rhs.naptanId }
    func hash(into hasher: inout Hasher) { hasher.combine(naptanId) }

    enum CodingKeys: String, CodingKey {
        case naptanId, commonName, lines
    }
}

// MARK: - Station Search Response

nonisolated struct TFLStopPointSearchResponse: Decodable {
    let matches: [TFLStopPointSearchMatch]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        matches = (try? c.decode([TFLStopPointSearchMatch].self, forKey: .matches)) ?? []
    }

    enum CodingKeys: String, CodingKey { case matches }
}

nonisolated struct TFLStopPointSearchMatch: Decodable {
    let id: String
    let name: String
    let lines: [TFLLineRef]

    // Defensive: `lines` can be absent or null in some TFL responses
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id    = try c.decode(String.self, forKey: .id)
        name  = try c.decode(String.self, forKey: .name)
        lines = (try? c.decode([TFLLineRef].self, forKey: .lines)) ?? []
    }

    enum CodingKeys: String, CodingKey { case id, name, lines }

    var asStopPoint: TFLStopPoint {
        TFLStopPoint(naptanId: id, commonName: name, lines: lines)
    }
}

// MARK: - Journey Planning

nonisolated struct TFLJourneyResponse: Decodable {
    let journeys: [TFLJourneyResult]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        journeys = (try? c.decode([TFLJourneyResult].self, forKey: .journeys)) ?? []
    }

    enum CodingKeys: String, CodingKey { case journeys }
}

nonisolated struct TFLJourneyResult: Codable {
    let startDateTime: String
    let arrivalDateTime: String
    let duration: Int?
    let legs: [TFLLeg]

    var durationMinutes: Int {
        if let d = duration { return d }
        let iso = ISO8601DateFormatter()
        guard let start = iso.date(from: startDateTime),
              let end   = iso.date(from: arrivalDateTime) else { return 0 }
        return Int(end.timeIntervalSince(start) / 60)
    }
}

nonisolated struct TFLLeg: Codable {
    let duration: Int?
    let departureTime: String?
    let arrivalTime: String?
    let departurePoint: TFLPoint
    let arrivalPoint: TFLPoint
    let path: TFLPath?
    let mode: TFLMode?
    let routeOptions: [TFLRouteOption]?

    var isTube: Bool { mode?.id == "tube" }
    /// A train of any kind (tube, Elizabeth line, Overground, DLR, National Rail), not a walk.
    var isTrain: Bool { TFLMode.trainModes.contains(mode?.id ?? "") }
    /// The line this leg runs on, e.g. "northern", "thameslink".
    var lineId: String? { routeOptions?.first?.lineIdentifier?.id }
    /// Where the train is heading, e.g. "Morden via Bank", "Luton Rail Station".
    var heading: String? { routeOptions?.first?.directions?.first(where: { !$0.isEmpty }) }
}

nonisolated struct TFLMode: Codable {
    let id: String

    /// Journey planner modes the app plans with; walking between them is added by TfL.
    static let trainModes = ["tube", "elizabeth-line", "overground", "dlr", "national-rail"]
}

nonisolated struct TFLRouteOption: Codable {
    /// Line name, e.g. "Northern", "Thameslink".
    let name: String?
    let lineIdentifier: TFLLineRef?
    let directions: [String]?
}

nonisolated struct TFLPoint: Codable {
    let commonName: String
    let naptanId: String?
}

/// /Line/{id}/Route/Sequence/{direction}: station order of each branch.
nonisolated struct TFLRouteSequence: Decodable {
    let orderedLineRoutes: [Route]
    /// Every stop on the line, keyed by the same NaPTANs the routes use. (The top-level
    /// `stations` list can't be used: it gives interchanges hub IDs, e.g. Bank is "HUBBAN".)
    let stops: [Stop]

    nonisolated struct Route: Decodable {
        let naptanIds: [String]
    }

    nonisolated struct Stop: Decodable {
        let id: String
        let name: String
    }

    private nonisolated struct StopPointSequence: Decodable {
        let stopPoint: [Stop]
    }

    init(orderedLineRoutes: [Route], stops: [Stop]) {
        self.orderedLineRoutes = orderedLineRoutes
        self.stops = stops
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        orderedLineRoutes = try c.decode([Route].self, forKey: .orderedLineRoutes)
        // Only used to read "via …" in arrivals, so a missing list isn't fatal.
        let sequences = (try? c.decode([StopPointSequence].self, forKey: .stopPointSequences)) ?? []
        stops = sequences.flatMap(\.stopPoint)
    }

    private enum CodingKeys: String, CodingKey { case orderedLineRoutes, stopPointSequences }
}

/// /Line/{id}/Timetable/{stop}: scheduled departures from one stop in one direction.
nonisolated struct TFLTimetable: Decodable {
    let stops: [Stop]
    let routes: [Route]

    nonisolated struct Stop: Decodable {
        let id: String
        let name: String
    }

    nonisolated struct Route: Decodable {
        let stationIntervals: [StationInterval]
        let schedules: [Schedule]
    }

    /// The stops a train pattern calls at after the departure stop, in order.
    nonisolated struct StationInterval: Decodable {
        let id: String
        let intervals: [Interval]
    }

    nonisolated struct Interval: Decodable {
        let stopId: String
    }

    /// One day type, e.g. "Monday - Thursday", "Friday", "Saturday (also Good Friday)".
    nonisolated struct Schedule: Decodable {
        let name: String
        let knownJourneys: [KnownJourney]
    }

    /// A departure from the stop. `hour` runs past 23 for trains after midnight.
    nonisolated struct KnownJourney: Decodable {
        let hour: String
        let minute: String
        let intervalId: Int
    }

    init(stops: [Stop], routes: [Route]) {
        self.stops = stops
        self.routes = routes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stops = (try? c.decode([Stop].self, forKey: .stops)) ?? []
        routes = try c.nestedContainer(keyedBy: TimetableKeys.self, forKey: .timetable)
            .decode([Route].self, forKey: .routes)
    }

    private enum CodingKeys: String, CodingKey { case stops, timetable }
    private enum TimetableKeys: String, CodingKey { case routes }
}

nonisolated struct TFLPath: Codable {
    let stopPoints: [TFLPathStopPoint]
}

nonisolated struct TFLPathStopPoint: Codable {
    let name: String
}

// MARK: - Arrival Predictions

nonisolated struct TFLArrivalPrediction: Identifiable, Codable {
    let id: String
    let lineId: String
    let lineName: String
    let platformName: String
    let direction: String?
    let towards: String?
    let destinationNaptanId: String?
    let destinationName: String?
    let expectedArrival: String
    let timeToStation: Int

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = (try? c.decode(String.self, forKey: .id))               ?? UUID().uuidString
        lineId              = (try? c.decode(String.self, forKey: .lineId))            ?? ""
        lineName            = (try? c.decode(String.self, forKey: .lineName))          ?? ""
        platformName        = (try? c.decode(String.self, forKey: .platformName))      ?? ""
        direction           = try? c.decode(String.self, forKey: .direction)
        towards             = try? c.decode(String.self, forKey: .towards)
        destinationNaptanId = try? c.decode(String.self, forKey: .destinationNaptanId)
        destinationName     = try? c.decode(String.self, forKey: .destinationName)
        expectedArrival     = (try? c.decode(String.self, forKey: .expectedArrival))   ?? ""
        timeToStation       = (try? c.decode(Int.self,   forKey: .timeToStation))      ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, lineId, lineName, platformName, direction, towards
        case destinationNaptanId, destinationName, expectedArrival, timeToStation
    }
}
