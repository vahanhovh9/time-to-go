import Foundation

// MARK: - Live implementation

final class TFLService: TFLServiceProtocol {

    private let baseURL = "https://api.tfl.gov.uk"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Debug state (written per-request, read by DevMenu via MainViewModel)

    static var debugJourneyCount: Int = 0
    static var debugJourneyDurations: [Int] = []
    static var debugDisambiguated: Bool = false
    static var debugResolvedFrom: String = ""
    static var debugResolvedTo: String = ""

    /// Resets debug state at the start of each fresh (non-retry) journey request.
    private static func resetDebugState() {
        debugJourneyCount = 0
        debugJourneyDurations = []
        debugDisambiguated = false
        debugResolvedFrom = ""
        debugResolvedTo = ""
    }

    // MARK: - Lines

    func fetchLines() async throws -> [TFLLine] {
        let url = try buildURL(path: "/Line/Mode/tube")
        let data = try await get(url)
        return try decode([TFLLine].self, from: data)
    }

    // MARK: - Stations
    // Uses the REST endpoint rather than the bulk stationdata ZIP
    // (/stationdata/tfl-stationdata-detailed.zip is for offline/bulk processing
    // and would require ZIP extraction — not suitable for a mobile app).

    func fetchStations(for lineId: String) async throws -> [TFLStopPoint] {
        let url = try buildURL(path: "/Line/\(lineId)/StopPoints")
        let data = try await get(url)
        return try decode([TFLStopPoint].self, from: data)
    }

    // MARK: - Journey

    func fetchJourney(from fromId: String, to toId: String, arrivingBy: Date) async throws -> TFLJourneyResult {
        let timeStr = timeFormatter.string(from: arrivingBy)
        let dateStr = dateFormatter.string(from: arrivingBy)
        return try await performJourneyRequest(from: fromId, to: toId, timeStr: timeStr, dateStr: dateStr, isRetry: false)
    }

    // TFL returns HTTP 300 when the station ID is ambiguous (e.g. a hub NaPTAN covering
    // multiple stops).  The 300 body contains disambiguated NaPTAN IDs — extract the best
    // match for each end of the journey and retry once with the resolved IDs.
    private func performJourneyRequest(
        from fromId: String,
        to toId: String,
        timeStr: String,
        dateStr: String,
        isRetry: Bool
    ) async throws -> TFLJourneyResult {
        if !isRetry { Self.resetDebugState() }
        let path = "/Journey/JourneyResults/\(fromId)/to/\(toId)"
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = [
            // Both date AND time are required — without date TFL assumes "today", which
            // causes 400 errors when the planned commute is on a future date (e.g. tomorrow).
            URLQueryItem(name: "date",              value: dateStr),
            URLQueryItem(name: "time",              value: timeStr),
            URLQueryItem(name: "timeIs",            value: "Arriving"),
            URLQueryItem(name: "mode",              value: "tube"),
            URLQueryItem(name: "journeyPreference", value: "LeastTime"),
            URLQueryItem(name: "nationalSearch",    value: "false")
        ]
        guard let url = components.url else { throw TFLError.invalidURL }

        let (data, status) = try await getRaw(url)

        switch status {
        case 200:
            let response = try decode(TFLJourneyResponse.self, from: data)
            guard !response.journeys.isEmpty else { throw TFLError.noJourneyFound }

            // Persist diagnostic info so DevMenu can display it without changing
            // the public API surface.
            TFLService.debugJourneyCount = response.journeys.count
            TFLService.debugJourneyDurations = response.journeys.map { $0.durationMinutes }

            // With timeIs=Arriving, we want the train departing as late as possible
            // so the user maximises home time. TFL's sort order varies by request
            // parameters and cannot be relied upon — sort explicitly.
            let best = response.journeys.max { a, b in
                Self.parseLocalDate(a.startDateTime) < Self.parseLocalDate(b.startDateTime)
            } ?? response.journeys[0]
            return best

        case 300 where !isRetry:
            // Resolve disambiguation and retry exactly once.
            // A 940GZZLU NaPTAN is already tube-specific — never "resolve" it via
            // disambiguation, which risks silently swapping it for the wrong station.
            let disambig = try? decode(TFLDisambiguationResponse.self, from: data)
            let resolvedFrom = fromId.hasPrefix("940GZZLU") ? fromId :
                (disambig?.fromLocationDisambiguation?.bestTubeNaptanId ?? fromId)
            let resolvedTo = toId.hasPrefix("940GZZLU") ? toId :
                (disambig?.toLocationDisambiguation?.bestTubeNaptanId ?? toId)

            TFLService.debugDisambiguated = true
            TFLService.debugResolvedFrom  = resolvedFrom
            TFLService.debugResolvedTo    = resolvedTo

            // If neither ID actually changed, retrying would return the same wrong result.
            guard resolvedFrom != fromId || resolvedTo != toId else {
                throw TFLError.badResponse(300)
            }
            return try await performJourneyRequest(
                from: resolvedFrom, to: resolvedTo,
                timeStr: timeStr, dateStr: dateStr,
                isRetry: true
            )

        default:
            throw TFLError.badResponse(status)
        }
    }

    // MARK: - Station Search

    func searchStations(query: String) async throws -> [TFLStopPoint] {
        guard !query.isEmpty else { return [] }

        // Let URLComponents handle percent-encoding of the path component
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.tfl.gov.uk"
        components.path   = "/StopPoint/Search/\(query)"
        components.queryItems = [
            URLQueryItem(name: "modes",      value: "tube"),
            URLQueryItem(name: "maxResults", value: "20")
        ]
        guard let url = components.url else { throw TFLError.invalidURL }
        let data = try await get(url)
        let response = try decode(TFLStopPointSearchResponse.self, from: data)
        return response.matches.map { $0.asStopPoint }
    }

    // MARK: - Line Status

    func fetchLineStatus(for lineIds: [String]) async throws -> [TFLLine] {
        guard !lineIds.isEmpty else { return [] }
        let ids = lineIds.joined(separator: ",")
        let url = try buildURL(path: "/Line/\(ids)/Status")
        let data = try await get(url)
        return try decode([TFLLine].self, from: data)
    }

    func fetchStopPointLines(naptanIds: [String]) async throws -> [String: [TFLLineRef]] {
        guard !naptanIds.isEmpty else { return [:] }
        let ids = naptanIds.prefix(20).joined(separator: ",")
        let url = try buildURL(path: "/StopPoint/\(ids)")
        let data = try await get(url)

        // TFL returns a single object for one ID, an array for many
        var details: [StopPointLinesDetail] = []
        if let array = try? decode([StopPointLinesDetail].self, from: data) {
            details = array
        } else if let single = try? decode(StopPointLinesDetail.self, from: data) {
            details = [single]
        }

        return Dictionary(
            uniqueKeysWithValues: details.compactMap { d in
                d.naptanId.isEmpty ? nil : (d.naptanId, d.lines.filter { !$0.id.isEmpty })
            }
        )
    }

    func resolveToTubeStopPoints(naptanIds: [String]) async throws -> [String: TFLStopPoint] {
        guard !naptanIds.isEmpty else { return [:] }

        let ids = naptanIds.prefix(20).joined(separator: ",")
        let url = try buildURL(path: "/StopPoint/\(ids)")
        let data = try await get(url)

        var details: [StopPointLinesDetail] = []
        if let array = try? decode([StopPointLinesDetail].self, from: data) {
            details = array
        } else if let single = try? decode(StopPointLinesDetail.self, from: data) {
            details = [single]
        }

        var result: [String: TFLStopPoint] = [:]
        for detail in details {
            guard !detail.naptanId.isEmpty else { continue }
            if let canonical = detail.canonicalTubeStop {
                result[detail.naptanId] = TFLStopPoint(
                    naptanId: canonical.naptanId,
                    commonName: "",
                    lines: canonical.lines.filter { !$0.id.isEmpty }
                )
            } else {
                print("[TFLService] resolveToTubeStopPoints: no canonical tube child for \(detail.naptanId) — excluded")
            }
        }
        // IDs absent from the response are simply not added — callers treat a missing key
        // as "unresolvable" and must not persist that station.
        return result
    }

    // MARK: - Helpers

    private func buildURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else { throw TFLError.invalidURL }
        return url
    }

    private func getRaw(_ url: URL) async throws -> (Data, Int) {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw TFLError.badResponse(0) }
        return (data, http.statusCode)
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, status) = try await getRaw(url)
        guard status == 200 else { throw TFLError.badResponse(status) }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw TFLError.decodingFailed(error.localizedDescription)
        }
    }

    // TFL operates in London — both formatters must always use Europe/London.
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HHmm"
        f.timeZone = TimeZone(identifier: "Europe/London")
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "Europe/London")
        return f
    }()

    // Used when sorting journeys by departure time. TFL returns dates as London-local
    // strings without a timezone offset, e.g. "2026-05-08T08:15:00".
    private static func parseLocalDate(_ string: String) -> Date {
        let f = DateFormatter()
        f.locale   = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/London")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.date(from: string)
            ?? ISO8601DateFormatter().date(from: string)
            ?? .distantPast
    }
}

// MARK: - Internal helpers

/// TFL Journey Planner HTTP 300 disambiguation response.
/// Returned when a station ID matches multiple stops — the body contains the best match.
private struct TFLDisambiguationResponse: Decodable {
    let fromLocationDisambiguation: Group?
    let toLocationDisambiguation: Group?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fromLocationDisambiguation = try? c.decode(Group.self, forKey: .fromLocationDisambiguation)
        toLocationDisambiguation   = try? c.decode(Group.self, forKey: .toLocationDisambiguation)
    }

    enum CodingKeys: String, CodingKey {
        case fromLocationDisambiguation, toLocationDisambiguation
    }

    struct Group: Decodable {
        let disambiguationOptions: [Option]

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            disambiguationOptions = (try? c.decode([Option].self, forKey: .disambiguationOptions)) ?? []
        }

        enum CodingKeys: String, CodingKey { case disambiguationOptions }

        // Only resolve to tube-format NaPTANs (940GZZLU…). A non-tube NaPTAN would cause
        // TFL to route via a distant/wrong stop, producing absurd journey times.
        var bestTubeNaptanId: String? {
            disambiguationOptions
                .filter { $0.tubeNaptanId != nil }
                .max(by: { $0.matchQuality < $1.matchQuality })?
                .tubeNaptanId
        }
    }

    struct Option: Decodable {
        // parameterValue is TFL's recommended NaPTAN for re-use in the journey planner URL —
        // more reliable than place.naptanId for disambiguation.
        let parameterValue: String
        let place: Place
        let matchQuality: Int

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            parameterValue = (try? c.decode(String.self, forKey: .parameterValue)) ?? ""
            place          = (try? c.decode(Place.self,  forKey: .place))          ?? Place(naptanId: "")
            matchQuality   = (try? c.decode(Int.self,    forKey: .matchQuality))   ?? 0
        }

        enum CodingKeys: String, CodingKey { case parameterValue, place, matchQuality }

        // Prefer parameterValue; fall back to place.naptanId. Returns nil if neither is a tube NaPTAN.
        var tubeNaptanId: String? {
            let candidates = [parameterValue, place.naptanId]
            return candidates.first { $0.hasPrefix("940GZZLU") }
        }
    }

    struct Place: Decodable {
        let naptanId: String
        init(naptanId: String) { self.naptanId = naptanId }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            naptanId = (try? c.decode(String.self, forKey: .naptanId)) ?? ""
        }
        enum CodingKeys: String, CodingKey { case naptanId }
    }
}

/// StopPoint shape used by /StopPoint/{ids}.
/// Captures children so composite/interchange NaPTANs can be resolved to
/// their canonical tube-specific child stop (940GZZLU… prefix).
private struct StopPointLinesDetail: Decodable {
    let naptanId: String
    let lines: [TFLLineRef]
    let modes: [String]
    let children: [StopPointChild]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        naptanId = (try? c.decode(String.self, forKey: .naptanId)) ?? ""
        lines    = (try? c.decode([TFLLineRef].self, forKey: .lines)) ?? []
        modes    = (try? c.decode([String].self,     forKey: .modes))  ?? []
        children = (try? c.decode([StopPointChild].self, forKey: .children)) ?? []
    }

    enum CodingKeys: String, CodingKey { case naptanId, lines, modes, children }

    /// Returns the canonical tube stop for this entry:
    /// • 940GZZ prefix + tube mode → already canonical (covers 940GZZLU traditional lines
    ///   and 940GZZB/940GZZN etc. Northern line extension stations)
    /// • otherwise (hub/composite) → first child with 940GZZ prefix and tube mode
    /// Returns nil if no canonical tube stop exists (station is not on the Tube).
    var canonicalTubeStop: StopPointChild? {
        if naptanId.hasPrefix("940GZZ") && modes.contains("tube") {
            return StopPointChild(naptanId: naptanId, modes: modes, lines: lines)
        }
        return children.first { $0.naptanId.hasPrefix("940GZZ") && $0.modes.contains("tube") }
    }
}

private struct StopPointChild: Decodable {
    let naptanId: String
    let modes: [String]
    let lines: [TFLLineRef]

    init(naptanId: String, modes: [String], lines: [TFLLineRef]) {
        self.naptanId = naptanId
        self.modes    = modes
        self.lines    = lines
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        naptanId = (try? c.decode(String.self,       forKey: .naptanId)) ?? ""
        modes    = (try? c.decode([String].self,     forKey: .modes))    ?? []
        lines    = (try? c.decode([TFLLineRef].self, forKey: .lines))    ?? []
    }

    enum CodingKeys: String, CodingKey { case naptanId, modes, lines }
}

// MARK: - Errors

enum TFLError: LocalizedError {
    case invalidURL
    case badResponse(Int)
    case noJourneyFound
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid TFL API URL."
        case .badResponse(let code) where code == 0:
            return "TFL API returned an unexpected response."
        case .badResponse(let code):
            return "TFL API error (HTTP \(code)). Check station IDs and try again."
        case .noJourneyFound:
            return "No journey found for the given route and time."
        case .decodingFailed(let msg):
            return "Failed to parse TFL response: \(msg)"
        }
    }
}

// MARK: - Mock (for previews and unit tests)

final class MockTFLService: TFLServiceProtocol {

    func fetchLines() async throws -> [TFLLine] {
        [
            TFLLine(id: "northern",  name: "Northern",  lineStatuses: [TFLLineStatus(statusSeverityDescription: "Good Service")]),
            TFLLine(id: "central",   name: "Central",   lineStatuses: [TFLLineStatus(statusSeverityDescription: "Good Service")]),
            TFLLine(id: "victoria",  name: "Victoria",  lineStatuses: [TFLLineStatus(statusSeverityDescription: "Minor Delays")])
        ]
    }

    func fetchStations(for lineId: String) async throws -> [TFLStopPoint] {
        [
            TFLStopPoint(naptanId: "940GZZLUBKF", commonName: "Baker Street Underground Station"),
            TFLStopPoint(naptanId: "940GZZLUCST", commonName: "Clapham South Underground Station"),
            TFLStopPoint(naptanId: "940GZZLUWSP", commonName: "Woodside Park Underground Station")
        ]
    }

    func fetchJourney(from fromId: String, to toId: String, arrivingBy: Date) async throws -> TFLJourneyResult {
        let iso = ISO8601DateFormatter()
        let departure = arrivingBy.addingTimeInterval(-30 * 60)
        return TFLJourneyResult(
            startDateTime:   iso.string(from: departure),
            arrivalDateTime: iso.string(from: arrivingBy),
            duration: 30,
            legs: []
        )
    }

    func fetchLineStatus(for lineIds: [String]) async throws -> [TFLLine] {
        try await fetchLines()
    }

    func fetchStopPointLines(naptanIds: [String]) async throws -> [String: [TFLLineRef]] {
        var result: [String: [TFLLineRef]] = [:]
        if naptanIds.contains("940GZZLUWSP") {
            result["940GZZLUWSP"] = [TFLLineRef(id: "jubilee", name: "Jubilee")]
        }
        if naptanIds.contains("940GZZLUBST") {
            result["940GZZLUBST"] = [
                TFLLineRef(id: "bakerloo",         name: "Bakerloo"),
                TFLLineRef(id: "circle",           name: "Circle"),
                TFLLineRef(id: "hammersmith-city", name: "Hammersmith & City"),
                TFLLineRef(id: "jubilee",          name: "Jubilee"),
                TFLLineRef(id: "metropolitan",     name: "Metropolitan")
            ]
        }
        return result
    }

    func resolveToTubeStopPoints(naptanIds: [String]) async throws -> [String: TFLStopPoint] {
        var result: [String: TFLStopPoint] = [:]
        for id in naptanIds {
            result[id] = TFLStopPoint(naptanId: id, commonName: "", lines: [])
        }
        return result
    }

    func searchStations(query: String) async throws -> [TFLStopPoint] {
        [
            TFLStopPoint(
                naptanId: "940GZZLUWSP",
                commonName: "West Hampstead Underground Station",
                lines: [TFLLineRef(id: "jubilee", name: "Jubilee")]
            ),
            TFLStopPoint(
                naptanId: "940GZZLUBST",
                commonName: "Baker Street Underground Station",
                lines: [
                    TFLLineRef(id: "bakerloo",            name: "Bakerloo"),
                    TFLLineRef(id: "circle",              name: "Circle"),
                    TFLLineRef(id: "hammersmith-city",    name: "Hammersmith & City"),
                    TFLLineRef(id: "jubilee",             name: "Jubilee"),
                    TFLLineRef(id: "metropolitan",        name: "Metropolitan")
                ]
            )
        ].filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }
}
