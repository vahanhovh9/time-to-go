import Foundation

// MARK: - Live implementation

final class TFLService: TFLServiceProtocol {

    private let baseURL = "https://api.tfl.gov.uk"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
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
        let path = "/Journey/JourneyResults/\(fromId)/to/\(toId)"

        var components = URLComponents(string: baseURL + path)!
        components.queryItems = [
            URLQueryItem(name: "time",              value: timeStr),
            URLQueryItem(name: "timeIs",            value: "Arriving"),
            URLQueryItem(name: "mode",              value: "tube"),
            URLQueryItem(name: "journeyPreference", value: "LeastTime"),
            URLQueryItem(name: "nationalSearch",    value: "false")
        ]

        guard let url = components.url else { throw TFLError.invalidURL }
        let data = try await get(url)
        let response = try decode(TFLJourneyResponse.self, from: data)

        // timeIs=Arriving guarantees every journey in the response arrives by arrivingBy.
        // TFL sorts them earliest-departure first, so .last gives the latest viable departure —
        // the one that maximises the user's time at home.
        guard let journey = response.journeys.last else { throw TFLError.noJourneyFound }
        return journey
    }

    // MARK: - Line Status

    func fetchLineStatus(for lineIds: [String]) async throws -> [TFLLine] {
        guard !lineIds.isEmpty else { return [] }
        let ids = lineIds.joined(separator: ",")
        let url = try buildURL(path: "/Line/\(ids)/Status")
        let data = try await get(url)
        return try decode([TFLLine].self, from: data)
    }

    // MARK: - Helpers

    private func buildURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else { throw TFLError.invalidURL }
        return url
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TFLError.badResponse
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw TFLError.decodingFailed(error.localizedDescription)
        }
    }

    // TFL operates in London — the time parameter must always be in Europe/London,
    // regardless of where the user's device is physically located.
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HHmm"
        f.timeZone = TimeZone(identifier: "Europe/London")
        return f
    }()
}

// MARK: - Errors

enum TFLError: LocalizedError {
    case invalidURL
    case badResponse
    case noJourneyFound
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid TFL API URL."
        case .badResponse:             return "TFL API returned an unexpected response."
        case .noJourneyFound:          return "No journey found for the given route and time."
        case .decodingFailed(let msg): return "Failed to parse TFL response: \(msg)"
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
}
