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
    /// Tube lines the journey actually uses, in order (from the journey planner).
    let lineIds: [String]
    /// Line of the first train the user boards — drives the departures board.
    var boardingLineId: String? { lineIds.first }
    /// Station where the user leaves the first train (differs from the destination when
    /// the journey has a change). Not cached; nil after a cache restore.
    var firstTrainExitId: String? = nil

    init(
        leaveHomeTime: Date,
        trainDepartureAtHomeStation: Date,
        trainArrivalAtOfficeStation: Date,
        journeyDurationMinutes: Int,
        numberOfStops: Int,
        serviceStatus: ServiceStatus,
        dayLabel: String,
        isFromCache: Bool = false,
        lineIds: [String] = []
    ) {
        self.leaveHomeTime               = leaveHomeTime
        self.trainDepartureAtHomeStation = trainDepartureAtHomeStation
        self.trainArrivalAtOfficeStation = trainArrivalAtOfficeStation
        self.journeyDurationMinutes      = journeyDurationMinutes
        self.numberOfStops               = numberOfStops
        self.serviceStatus               = serviceStatus
        self.dayLabel                    = dayLabel
        self.isFromCache                 = isFromCache
        self.lineIds                     = lineIds
    }

    /// Reconstruct a CommuteResult from a CachedCommuteResult.
    init(from cache: CachedCommuteResult) {
        self.init(
            leaveHomeTime:               cache.leaveHomeTime,
            trainDepartureAtHomeStation: cache.trainDepartureAtHomeStation,
            trainArrivalAtOfficeStation: cache.trainArrivalAtOfficeStation,
            journeyDurationMinutes:      cache.journeyDurationMinutes,
            numberOfStops:               cache.numberOfStops,
            serviceStatus:               ServiceStatus(cachedText: cache.serviceStatusText),
            dayLabel:                    cache.dayLabel,
            isFromCache:                 true,
            lineIds:                     cache.lineIds ?? []
        )
    }
}

extension CommuteResult {
    func withFirstTrainExit(_ id: String?) -> CommuteResult {
        var copy = self
        copy.firstTrainExitId = id
        return copy
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

    /// Rebuilds a status from the `displayText` stored in the cache.
    init(cachedText text: String) {
        switch text {
        case ServiceStatus.goodService.displayText:        self = .goodService
        case ServiceStatus.minorDelays("").displayText:    self = .minorDelays("")
        case ServiceStatus.severeDelays("").displayText:   self = .severeDelays("")
        default:                                           self = .unknown(text)
        }
    }

    var isGood: Bool {
        if case .goodService = self { return true }
        return false
    }
}
