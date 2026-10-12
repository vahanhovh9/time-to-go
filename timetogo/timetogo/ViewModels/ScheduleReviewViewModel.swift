import Foundation
import Combine

@MainActor
final class ScheduleReviewViewModel: ObservableObject {

    @Published var entries: [ScheduleEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: ScheduleReviewService

    nonisolated init(service: ScheduleReviewService = ScheduleReviewService()) {
        self.service = service
    }

    func load(context: ScheduleReviewContext) {
        entries = []
        isLoading = true
        errorMessage = nil
        Task {
            do {
                entries = try await service.fetchSchedule(context: context)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
