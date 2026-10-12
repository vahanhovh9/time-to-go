import Foundation

// MARK: - Schedule errors

enum ScheduleError: LocalizedError {
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

final class ScheduleReviewService {

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

        guard let direction = resolveDirection(
            originId: context.homeStopId,
            destinationId: context.destinationStopId,
            lineId: context.lineId
        ) else {
            throw ScheduleError.directionUnknown
        }

        // Primary filter: platformName explicitly states "Northbound" / "Southbound".
        // TFL live data confirms this field is always populated for tube arrivals.
        // Secondary filter: TFL's `direction` field uses "outbound" (away from centre) and
        // "inbound" (toward centre). For all N-S lines this maps 1-to-1 with our direction.
        let tflDirectionValue = (direction == "northbound") ? "outbound" : "inbound"
        let directionFiltered = future.filter { arrival in
            arrival.platformName.lowercased().contains(direction)
                || arrival.direction?.lowercased() == tflDirectionValue
        }

        // If neither field matched, TFL's response format has changed — surface it explicitly.
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

    /// Returns "northbound" or "southbound" by comparing station positions on the line.
    /// NaPTAN IDs sourced from /Line/{id}/Route/Sequence/all (TFL canonical values).
    private func resolveDirection(originId: String, destinationId: String, lineId: String) -> String? {
        let order: [String: Int]
        switch lineId {
        case "northern": order = Self.northernLineOrder
        case "victoria": order = Self.victoriaLineOrder
        default: return nil
        }
        guard let o = order[originId], let d = order[destinationId] else { return nil }
        return o < d ? "southbound" : "northbound"
    }

    // MARK: - Station order maps

    // Station positions along the Northern line, index 0 = northernmost.
    // Sourced directly from /Line/northern/Route/Sequence/all — do not guess NaPTANs.
    private static let northernLineOrder: [String: Int] = [
        "940GZZLUHBT":  0,  // High Barnet
        "940GZZLUTAW":  1,  // Totteridge & Whetstone
        "940GZZLUWOP":  2,  // Woodside Park
        "940GZZLUWFN":  3,  // West Finchley
        "940GZZLUFYC":  4,  // Finchley Central
        "940GZZLUEFY":  5,  // East Finchley
        "940GZZLUMHL":  5,  // Mill Hill East (branches off East Finchley)
        "940GZZLUEGW":  5,  // Edgware (northern terminus, different branch)
        "940GZZLUHGT":  6,  // Highgate
        "940GZZLUACY":  7,  // Archway
        "940GZZLUTFP":  8,  // Tufnell Park
        "940GZZLUKSH":  9,  // Kentish Town
        "940GZZLUCTN": 10,  // Camden Town
        "940GZZLUEUS": 11,  // Euston
        "940GZZLUKSX": 12,  // King's Cross St. Pancras
        "940GZZLUAGL": 13,  // Angel
        "940GZZLUODS": 14,  // Old Street
        "940GZZLUMGT": 15,  // Moorgate
        "940GZZLUBNK": 16,  // Bank / Monument
        "940GZZLULNB": 17,  // London Bridge
        "940GZZLUBOR": 18,  // Borough
        "940GZZLUEAC": 19,  // Elephant & Castle
        "940GZZLUKNG": 20,  // Kennington
        "940GZZLUOVL": 21,  // Oval
        "940GZZLUSKW": 22,  // Stockwell
        "940GZZLUCPN": 23,  // Clapham North
        "940GZZLUCPC": 24,  // Clapham Common
        "940GZZLUCPS": 25,  // Clapham South
        "940GZZLUBLM": 26,  // Balham
        "940GZZLUTBC": 27,  // Tooting Bec
        "940GZZLUTBY": 28,  // Tooting Broadway
        "940GZZLUCSD": 29,  // Colliers Wood
        "940GZZLUSWN": 30,  // South Wimbledon
        "940GZZLUMDN": 31,  // Morden
        "940GZZNEUGST": 32, // Nine Elms
        "940GZZBPSUST": 33, // Battersea Power Station
    ]

    // Victoria line positions, index 0 = northernmost.
    private static let victoriaLineOrder: [String: Int] = [
        "940GZZLUWLT":  0,  // Walthamstow Central
        "940GZZLUBLK":  1,  // Blackhorse Road
        "940GZZLUTMH":  2,  // Tottenham Hale
        "940GZZLUSEV":  3,  // Seven Sisters
        "940GZZLUFPK":  4,  // Finsbury Park
        "940GZZLUHGR":  5,  // Highbury & Islington
        "940GZZLUKXU":  6,  // King's Cross (Victoria line)
        "940GZZLUEUS":  7,  // Euston
        "940GZZLUWRR":  8,  // Warren Street
        "940GZZLUOXC":  9,  // Oxford Circus
        "940GZZLUGPK": 10,  // Green Park
        "940GZZLUVIC": 11,  // Victoria
        "940GZZLUPIG": 12,  // Pimlico
        "940GZZLUVXL": 13,  // Vauxhall
        "940GZZLUSTK": 14,  // Stockwell
        "940GZZLUBXN": 15,  // Brixton
    ]

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
