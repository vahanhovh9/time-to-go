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

    init() {
        self.service = TFLService()
    }

    init(service: TFLServiceProtocol) {
        self.service = service
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
                stationsCache[lineId] = fetched.sorted { $0.commonName < $1.commonName }
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

    func searchStations(query: String) {
        guard query.count >= 2 else {
            stationSearchResults = []
            return
        }
        Task {
            isSearchingStations = true
            do {
                var results = try await service.searchStations(query: query)

                // The search endpoint doesn't return line info — enrich via batch lookup
                if !results.isEmpty {
                    let ids = results.map { $0.naptanId }
                    let lineMap = (try? await service.fetchStopPointLines(naptanIds: ids)) ?? [:]
                    if !lineMap.isEmpty {
                        results = results.map { station in
                            guard let lines = lineMap[station.naptanId], !lines.isEmpty else {
                                return station
                            }
                            return TFLStopPoint(naptanId: station.naptanId, commonName: station.commonName, lines: lines)
                        }
                    }
                }

                stationSearchResults = results
            } catch {
                stationSearchResults = []
            }
            isSearchingStations = false
        }
    }

    func clearStationSearch() {
        stationSearchResults = []
    }

    // MARK: - Lookup helpers

    func line(for id: String) -> TFLLine? {
        lines.first { $0.id == id }
    }

    func station(naptanId: String, lineId: String) -> TFLStopPoint? {
        stationsCache[lineId]?.first { $0.naptanId == naptanId }
    }
}
