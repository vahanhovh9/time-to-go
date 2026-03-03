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

    private let service: TFLServiceProtocol

    /// Production init — uses the live TFL service.
    init() {
        self.service = TFLService()
    }

    /// Injectable init for previews and unit tests.
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

    // MARK: - Stations

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

    // MARK: - Lookup helpers

    func line(for id: String) -> TFLLine? {
        lines.first { $0.id == id }
    }

    func station(naptanId: String, lineId: String) -> TFLStopPoint? {
        stationsCache[lineId]?.first { $0.naptanId == naptanId }
    }
}
