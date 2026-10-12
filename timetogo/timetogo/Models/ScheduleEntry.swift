import Foundation

/// Input needed to fetch and filter live arrivals for a given journey leg.
struct ScheduleReviewContext: Equatable {
    /// Stop point to query for live arrivals.
    let stopId: String
    /// Line ID used to filter arrivals to only those on the user's line.
    let lineId: String
    /// NaPTAN of the origin station (used for direction inference via position map).
    let homeStopId: String
    /// NaPTAN of the destination station (used for direction inference via position map).
    let destinationStopId: String
    /// Human-readable destination name shown in the sheet title.
    let destinationStationName: String
}

/// A single upcoming train departure shown in the schedule sheet.
struct ScheduleEntry: Identifiable {
    let id: String
    let lineName: String
    let platformName: String
    let destinationName: String
    let towards: String
    let expectedArrival: Date
    let minutesUntilArrival: Int
}
