import Foundation
import Combine

@MainActor
final class ScheduleReviewViewModel: ObservableObject {

    @Published var entries: [ScheduleEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: ScheduleReviewService
    /// The journey the entries belong to.
    private var loadedContext: ScheduleReviewContext?
    /// Only the latest load may update the board, so a slow older one can't overwrite it.
    private var latestLoad = UUID()

    init(service: ScheduleReviewService = ScheduleReviewService()) {
        self.service = service
    }

    /// Fetches departures. Refreshing the same journey keeps its trains on screen meanwhile.
    func load(context: ScheduleReviewContext) async {
        if context != loadedContext {
            entries = []
            loadedContext = context
        }
        let load = UUID()
        latestLoad = load
        isLoading = true
        errorMessage = nil
        do {
            let fresh = try await service.fetchSchedule(context: context)
            guard load == latestLoad else { return }
            entries = fresh
        } catch {
            guard load == latestLoad else { return }
            errorMessage = UserFacingError.message(for: error)
        }
        isLoading = false
    }
}
