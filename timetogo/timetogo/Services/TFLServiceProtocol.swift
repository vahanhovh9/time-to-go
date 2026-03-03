import Foundation

/// Defines all interactions with the TFL Unified API.
protocol TFLServiceProtocol {
    /// Returns all London Underground lines.
    func fetchLines() async throws -> [TFLLine]

    /// Returns all stop points (stations) for a given line ID (e.g. "northern").
    func fetchStations(for lineId: String) async throws -> [TFLStopPoint]

    /// Plans the fastest journey between two station IDs, arriving by the given time.
    func fetchJourney(from fromId: String, to toId: String, arrivingBy: Date) async throws -> TFLJourneyResult

    /// Returns current service status for the given line IDs.
    func fetchLineStatus(for lineIds: [String]) async throws -> [TFLLine]
}
