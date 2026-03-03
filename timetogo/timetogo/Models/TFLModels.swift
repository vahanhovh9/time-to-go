import Foundation

// MARK: - Lines

struct TFLLine: Identifiable, Codable, Hashable, CustomStringConvertible {
    let id: String
    let name: String
    let lineStatuses: [TFLLineStatus]?

    /// Placeholder used as the "Choose" item in Dropdown.
    static let placeholder = TFLLine(id: "", name: "Choose", lineStatuses: nil)

    var description: String { name }

    var serviceStatus: String {
        lineStatuses?.first?.statusSeverityDescription ?? "Unknown"
    }

    static func == (lhs: TFLLine, rhs: TFLLine) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct TFLLineStatus: Codable {
    let statusSeverityDescription: String
}

// MARK: - Stop Points (Stations)

struct TFLStopPoint: Identifiable, Codable, Hashable, CustomStringConvertible {
    let naptanId: String
    let commonName: String

    /// Placeholder used as the "Choose" item in Dropdown.
    static let placeholder = TFLStopPoint(naptanId: "", commonName: "Choose")

    var id: String { naptanId }

    /// Display name with common TFL suffixes removed.
    var displayName: String {
        commonName
            .replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
            .replacingOccurrences(of: " Station", with: "")
    }

    var description: String { displayName }

    static func == (lhs: TFLStopPoint, rhs: TFLStopPoint) -> Bool { lhs.naptanId == rhs.naptanId }
    func hash(into hasher: inout Hasher) { hasher.combine(naptanId) }

    enum CodingKeys: String, CodingKey {
        case naptanId
        case commonName
    }
}

// MARK: - Journey Planning

/// Root response from GET /Journey/JourneyResults/{from}/to/{to}
struct TFLJourneyResponse: Codable {
    let journeys: [TFLJourneyResult]
}

struct TFLJourneyResult: Codable {
    /// ISO-8601 departure datetime, e.g. "2026-01-23T08:19:00"
    let startDateTime: String
    /// ISO-8601 arrival datetime
    let arrivalDateTime: String
    let duration: Int?
    let legs: [TFLLeg]

    /// Falls back to calculating from timestamps if `duration` is absent.
    var durationMinutes: Int {
        if let d = duration { return d }
        let iso = ISO8601DateFormatter()
        guard let start = iso.date(from: startDateTime),
              let end   = iso.date(from: arrivalDateTime) else { return 0 }
        return Int(end.timeIntervalSince(start) / 60)
    }
}

struct TFLLeg: Codable {
    let duration: Int?
    let departurePoint: TFLPoint
    let arrivalPoint: TFLPoint
    let path: TFLPath?
}

struct TFLPoint: Codable {
    let commonName: String
}

struct TFLPath: Codable {
    let stopPoints: [TFLPathStopPoint]
}

struct TFLPathStopPoint: Codable {
    let name: String
}
