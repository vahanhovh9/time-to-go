import Foundation
import Combine

/// Shared observable store that caches TFL lines and stations.
/// Injected as @EnvironmentObject so onboarding views can load data on demand.
@MainActor
final class TFLDataStore: ObservableObject {

    @Published var lines: [TFLLine] = []
    @Published var isLoadingLines = false
    @Published var stationsCache: [String: [TFLStopPoint]] = [:]
    @Published var loadingLineIds: Set<String> = []
    @Published var error: String?

    // MARK: - Station search

    @Published var stationSearchResults: [TFLStopPoint] = []
    @Published var isSearchingStations = false

    private let service: TFLServiceProtocol

    /// Every tube station, bundled in the app (Resources/tube-stations.json) so search is
    /// instant and offline. IDs are already canonical 940GZZ… NaPTANs with tube lines only.
    private var bundledStations: [IndexedStation] = []
    private var bundleLoad: Task<Void, Never>?
    private var liveSearch: Task<Void, Never>?

    init() {
        self.service = TFLService()
        startBundleLoad()
    }

    init(service: TFLServiceProtocol) {
        self.service = service
        startBundleLoad()
    }

    private func startBundleLoad() {
        bundleLoad = Task {
            bundledStations = await Self.loadBundledStations()
        }
    }

    @concurrent
    private nonisolated static func loadBundledStations() async -> [IndexedStation] {
        guard let url = Bundle.main.url(forResource: "tube-stations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stations = try? JSONDecoder().decode([TFLStopPoint].self, from: data) else {
            return []
        }
        return stations
            .map(IndexedStation.init)
            .sorted { $0.station.displayName.localizedStandardCompare($1.station.displayName) == .orderedAscending }
    }

    // MARK: - Lines

    func loadLines() {
        guard lines.isEmpty, !isLoadingLines else { return }
        Task {
            isLoadingLines = true
            error = nil
            do {
                lines = try await service.fetchLines()
                    .sorted { $0.name < $1.name }
            } catch {
                self.error = error.localizedDescription
            }
            isLoadingLines = false
        }
    }

    // MARK: - Stations (by line, used for legacy lookups)

    func loadStations(for lineId: String) {
        guard stationsCache[lineId] == nil, !loadingLineIds.contains(lineId) else { return }
        Task {
            loadingLineIds.insert(lineId)
            do {
                let fetched = try await service.fetchStations(for: lineId)
                // The /Line/{id}/StopPoints endpoint can return non-canonical IDs
                // (e.g. 940GZZBPSUST on Northern). Filter to tube-canonical IDs only.
                let canonical = fetched.filter { station in
                    if station.naptanId.hasPrefix("940GZZ") { return true }
                    print("[TFLDataStore] loadStations(\(lineId)): dropping \(station.naptanId) — not a canonical tube ID")
                    return false
                }
                stationsCache[lineId] = canonical.sorted { $0.commonName < $1.commonName }
            } catch {
                self.error = error.localizedDescription
            }
            loadingLineIds.remove(lineId)
        }
    }

    func stations(for lineId: String) -> [TFLStopPoint] {
        stationsCache[lineId] ?? []
    }

    func isLoadingStations(for lineId: String) -> Bool {
        loadingLineIds.contains(lineId)
    }

    // MARK: - Station search

    /// Filters the bundled station list. An empty query lists every station A–Z.
    /// Falls back to the live TfL search only if the bundled list couldn't be loaded.
    func searchStations(query: String) {
        liveSearch?.cancel()
        let normalized = IndexedStation.normalize(query)

        guard !bundledStations.isEmpty else {
            guard let bundleLoad else { return }
            // First search can land before the bundle has finished loading (it takes milliseconds).
            isSearchingStations = true
            liveSearch = Task {
                await bundleLoad.value
                guard !Task.isCancelled else { return }
                if bundledStations.isEmpty {
                    await searchStationsLive(query: query)
                } else {
                    isSearchingStations = false
                    stationSearchResults = Self.filter(bundledStations, normalized)
                }
            }
            return
        }

        isSearchingStations = false
        stationSearchResults = Self.filter(bundledStations, normalized)
    }

    private static func filter(_ stations: [IndexedStation], _ query: String) -> [TFLStopPoint] {
        guard !query.isEmpty else { return stations.map(\.station) }
        return stations
            .compactMap { s -> (rank: Int, station: TFLStopPoint)? in
                if s.key.hasPrefix(query) { return (0, s.station) }
                if s.words.contains(where: { $0.hasPrefix(query) }) { return (1, s.station) }
                if s.key.contains(query) { return (2, s.station) }
                return nil
            }
            .sorted { $0.rank != $1.rank ? $0.rank < $1.rank : $0.station.displayName < $1.station.displayName }
            .map(\.station)
    }

    /// Live TfL search (fallback only): search, then resolve hub IDs to canonical tube IDs.
    private func searchStationsLive(query: String) async {
        guard query.count >= 2 else {
            stationSearchResults = []
            isSearchingStations = false
            return
        }
        isSearchingStations = true
        defer { isSearchingStations = false }
        do {
            var results = try await service.searchStations(query: query)
            if !results.isEmpty {
                let ids = results.map { $0.naptanId }
                let resolved = (try? await service.resolveToTubeStopPoints(naptanIds: ids)) ?? [:]
                results = results.compactMap { station in
                    guard let r = resolved[station.naptanId] else { return nil }
                    return TFLStopPoint(
                        naptanId: r.naptanId,
                        commonName: station.commonName,
                        lines: r.lines.isEmpty ? station.lines : r.lines
                    )
                }
            }
            guard !Task.isCancelled else { return }
            stationSearchResults = results
        } catch {
            guard !Task.isCancelled else { return }
            stationSearchResults = []
        }
    }

    func clearStationSearch() {
        liveSearch?.cancel()
        stationSearchResults = []
        isSearchingStations = false
    }

    // MARK: - Lookup helpers

    func line(for id: String) -> TFLLine? {
        lines.first { $0.id == id }
    }

    func station(naptanId: String, lineId: String) -> TFLStopPoint? {
        stationsCache[lineId]?.first { $0.naptanId == naptanId }
    }
}

// MARK: - Search index

/// A station plus its pre-normalised search keys, built once when the bundle loads.
nonisolated struct IndexedStation: Sendable {
    let station: TFLStopPoint
    /// Normalised display name, e.g. "kings cross st pancras".
    let key: String
    let words: [Substring]

    init(_ station: TFLStopPoint) {
        self.station = station
        self.key = Self.normalize(station.displayName)
        self.words = key.split(separator: " ")
    }

    /// Lowercased, accent-free, "&" → "and", punctuation dropped, spaces collapsed —
    /// so "Kings Cross", "king's cross" and "KING’S CROSS" all match.
    static func normalize(_ text: String) -> String {
        let folded = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "")
            .replacingOccurrences(of: ".", with: "")
        let kept = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(kept).split(separator: " ").joined(separator: " ")
    }
}
