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

    /// Searches all tube stations by name query.
    func searchStations(query: String) async throws -> [TFLStopPoint]

    /// Batch-fetches line information for up to 20 stop points by NaPTAN ID.
    /// The /StopPoint/Search endpoint doesn't include lines; this fills the gap.
    func fetchStopPointLines(naptanIds: [String]) async throws -> [String: [TFLLineRef]]

    /// Resolves each NaPTAN to its canonical Tube stop point (940GZZLU…).
    /// Hub/interchange NaPTANs (e.g. HUBOLD) are resolved to the tube-mode child stop.
    /// IDs already in 940GZZLU format are kept as-is.
    /// Returns a map of input NaPTAN → resolved TFLStopPoint (with canonical ID and lines).
    func resolveToTubeStopPoints(naptanIds: [String]) async throws -> [String: TFLStopPoint]

    /// Returns live arrival predictions for all trains at a given stop point.
    func fetchArrivals(stopId: String) async throws -> [TFLArrivalPrediction]

    /// Returns live arrival predictions for a specific line at a given stop.
    /// Preferred over fetchArrivals when the line is known — the server filters by line.
    func fetchLineArrivals(lineId: String, stopId: String) async throws -> [TFLArrivalPrediction]
}
