import Foundation

// MARK: - Lines

struct TFLLine: Identifiable, Codable, Hashable, CustomStringConvertible {
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

struct TFLLineStatus: Codable {
    let statusSeverityDescription: String
}

// MARK: - Line Reference (lightweight, used in station search results)

struct TFLLineRef: Codable, Hashable {
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

struct TFLStopPoint: Identifiable, Codable, Hashable, CustomStringConvertible {
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

struct TFLStopPointSearchResponse: Decodable {
    let matches: [TFLStopPointSearchMatch]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        matches = (try? c.decode([TFLStopPointSearchMatch].self, forKey: .matches)) ?? []
    }

    enum CodingKeys: String, CodingKey { case matches }
}

struct TFLStopPointSearchMatch: Decodable {
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

struct TFLJourneyResponse: Decodable {
    let journeys: [TFLJourneyResult]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        journeys = (try? c.decode([TFLJourneyResult].self, forKey: .journeys)) ?? []
    }

    enum CodingKeys: String, CodingKey { case journeys }
}

struct TFLJourneyResult: Codable {
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
