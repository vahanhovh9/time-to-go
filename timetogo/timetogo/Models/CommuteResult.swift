import Foundation

/// Computed commute plan shown on the main screen.
struct CommuteResult {
    /// The time the user should leave home.
    let leaveHomeTime: Date
    /// When the train departs from the user's home station.
    let trainDepartureAtHomeStation: Date
    /// When the train arrives at the user's office station.
    let trainArrivalAtOfficeStation: Date
    /// Total in-train duration in minutes.
    let journeyDurationMinutes: Int
    /// Number of tube stops in the journey.
    let numberOfStops: Int
    /// Current service status across the relevant lines.
    let serviceStatus: ServiceStatus
    /// Human-readable day label, e.g. "Today at" or "Tomorrow at".
    let dayLabel: String
}

// MARK: - Service Status

enum ServiceStatus {
    case goodService
    case minorDelays(String)
    case severeDelays(String)
    case unknown(String)

    var displayText: String {
        switch self {
        case .goodService:              return "Service status: No delays"
        case .minorDelays:              return "Service status: Minor delays"
        case .severeDelays:             return "Service status: Severe delays"
        case .unknown(let detail):      return "Service status: \(detail)"
        }
    }

    var isGood: Bool {
        if case .goodService = self { return true }
        return false
    }
}
