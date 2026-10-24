import Foundation
import Combine

/// Shared observable store that caches TFL lines and stations.
/// Injected as @EnvironmentObject so setup views can load data on demand.
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
    /// Stations the user picked recently, newest first; shared by every station picker.
    @Published private(set) var recentStations: [TFLStopPoint] = []

    private static let recentStationsKey = "com.timetogo.recentStations"
    private static let recentStationsLimit = 5

    private let service: TFLServiceProtocol

    /// Every tube station, bundled in the app (Resources/tube-stations.json) so search is
    /// instant and offline. IDs are already canonical 940GZZ… NaPTANs with tube lines only.
    private var bundledStations: [IndexedStation] = []
    private var bundleLoad: Task<Void, Never>?
    private var liveSearch: Task<Void, Never>?

    init() {
        self.service = TFLService()
        loadRecentStations()
        startBundleLoad()
    }

    init(service: TFLServiceProtocol) {
        self.service = service
        loadRecentStations()
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

    /// Exact matches first (name starts with the query, then a word does, then anywhere),
    /// then close spellings ("toteridge" → Totteridge & Whetstone), fewest typos first.
    private static func filter(_ stations: [IndexedStation], _ query: String) -> [TFLStopPoint] {
        guard !query.isEmpty else { return stations.map(\.station) }
        let maxTypos = IndexedStation.allowedTypos(forQueryLength: query.count)
        return stations
            .compactMap { s -> (rank: Int, station: TFLStopPoint)? in
                if s.key.hasPrefix(query) { return (0, s.station) }
                if s.words.contains(where: { $0.hasPrefix(query) }) { return (1, s.station) }
                if s.key.contains(query) { return (2, s.station) }
                if maxTypos > 0, let typos = s.typos(from: query, max: maxTypos) { return (3 + typos, s.station) }
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

    // MARK: - Recent stations

    /// Remembers a picked station: moves it to the front, keeps the latest 5.
    func rememberStation(_ station: TFLStopPoint) {
        guard !station.naptanId.isEmpty else { return }
        recentStations.removeAll { $0.naptanId == station.naptanId }
        recentStations.insert(station, at: 0)
        recentStations = Array(recentStations.prefix(Self.recentStationsLimit))
        saveRecentStations()
    }

    func clearRecentStations() {
        recentStations = []
        saveRecentStations()
    }

    /// Search results with recently picked stations moved to the top, in their recent order.
    var stationSearchResultsWithRecentFirst: [TFLStopPoint] {
        let recentIds = recentStations.map(\.naptanId)
        let recent = recentIds.compactMap { id in stationSearchResults.first { $0.naptanId == id } }
        let others = stationSearchResults.filter { !recentIds.contains($0.naptanId) }
        return recent + others
    }

    private func loadRecentStations() {
        guard let data = UserDefaults.standard.data(forKey: Self.recentStationsKey),
              let stations = try? JSONDecoder().decode([TFLStopPoint].self, from: data) else { return }
        recentStations = stations
    }

    private func saveRecentStations() {
        guard let data = try? JSONEncoder().encode(recentStations) else { return }
        UserDefaults.standard.set(data, forKey: Self.recentStationsKey)
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

    // MARK: Typo tolerance

    /// Typos allowed for a query: none for 1–3 letters (too many accidental matches),
    /// 1 for 4–5, 2 for 6–8, 3 for longer.
    static func allowedTypos(forQueryLength length: Int) -> Int {
        switch length {
        case ..<4: return 0
        case 4...5: return 1
        case 6...8: return 2
        default: return 3
        }
    }

    /// Fewest typos (insertions, deletions, substitutions, swapped neighbours) needed for the
    /// query to match the start of the name or of any word in it, also ignoring spaces
    /// ("westhampstead"). nil when more than `max`.
    func typos(from query: String, max: Int) -> Int? {
        let q = Array(query.unicodeScalars)
        var candidates = [key, key.replacingOccurrences(of: " ", with: "")]
        // Each word onwards: "hampstead" in "west hampstead".
        for word in words.dropFirst() {
            candidates.append(String(key[word.startIndex...]))
        }
        let best = candidates.map { Self.prefixDistance(q, Array($0.unicodeScalars)) }.min() ?? .max
        return best <= max ? best : nil
    }

    /// Edit distance between `a` and the closest prefix of `b` (optimal string alignment).
    private static func prefixDistance(_ a: [Unicode.Scalar], _ b: [Unicode.Scalar]) -> Int {
        let m = a.count, n = b.count
        guard m > 0 else { return 0 }
        guard n > 0 else { return m }
        var d = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0...m { d[i][0] = i }
        for j in 0...n { d[0][j] = j }
        for i in 1...m {
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                d[i][j] = Swift.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    d[i][j] = Swift.min(d[i][j], d[i - 2][j - 2] + 1)
                }
            }
        }
        // Any prefix of b may match: the query is usually only the start of a name.
        return d[m].min() ?? m
    }
}
