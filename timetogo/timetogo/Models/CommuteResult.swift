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
    /// Human-readable day label, e.g. "Today", "Tomorrow", "Upcoming Tuesday".
    let dayLabel: String
    /// True when reconstructed from cache rather than a live API call.
    let isFromCache: Bool

    init(
        leaveHomeTime: Date,
        trainDepartureAtHomeStation: Date,
        trainArrivalAtOfficeStation: Date,
        journeyDurationMinutes: Int,
        numberOfStops: Int,
        serviceStatus: ServiceStatus,
        dayLabel: String,
        isFromCache: Bool = false
    ) {
        self.leaveHomeTime               = leaveHomeTime
        self.trainDepartureAtHomeStation = trainDepartureAtHomeStation
        self.trainArrivalAtOfficeStation = trainArrivalAtOfficeStation
        self.journeyDurationMinutes      = journeyDurationMinutes
        self.numberOfStops               = numberOfStops
        self.serviceStatus               = serviceStatus
        self.dayLabel                    = dayLabel
        self.isFromCache                 = isFromCache
    }

    /// Reconstruct a CommuteResult from a CachedCommuteResult.
    init(from cache: CachedCommuteResult) {
        self.init(
            leaveHomeTime:               cache.leaveHomeTime,
            trainDepartureAtHomeStation: cache.trainDepartureAtHomeStation,
            trainArrivalAtOfficeStation: cache.trainArrivalAtOfficeStation,
            journeyDurationMinutes:      cache.journeyDurationMinutes,
            numberOfStops:               cache.numberOfStops,
            serviceStatus:               .unknown(cache.serviceStatusText),
            dayLabel:                    cache.dayLabel,
            isFromCache:                 true
        )
    }
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
