import Foundation

/// Orchestrates a full commute calculation:
/// 1. Find the next working commute day.
/// 2. Work backwards from the desired office arrival time.
/// 3. Query TFL for the journey using station naptanIds.
/// 4. Subtract walking time + safety buffer to derive "leave home at".
final class CommuteCalculationService {

    /// Extra buffer added on top of walking time so the user doesn't miss their train.
    private let safetyBufferMinutes: Int = 2

    private let tflService: TFLServiceProtocol

    init(tflService: TFLServiceProtocol = TFLService()) {
        self.tflService = tflService
    }

    // MARK: - Public API

    func calculate(for settings: UserSettings) async throws -> CommuteResult {
        let commuteDate = nextCommuteDate(from: settings)

        // Target train arrival = desired office arrival − walk from station to office
        let trainArrivalTarget = applyTime(settings.arrivalTime, to: commuteDate)
            .addingTimeInterval(TimeInterval(-settings.walkingMinutesToOffice * 60))

        // Query TFL using naptanIds
        let journey = try await tflService.fetchJourney(
            from: settings.homeStationId,
            to: settings.officeStationId,
            arrivingBy: trainArrivalTarget
        )

        let trainDeparture = Self.parseTFLDate(journey.startDateTime) ?? trainArrivalTarget
        let trainArrival   = Self.parseTFLDate(journey.arrivalDateTime) ?? trainArrivalTarget

        let numberOfStops = journey.legs.reduce(0) { $0 + ($1.path?.stopPoints.count ?? 0) }

        // leave home = train departure − walk to station − safety buffer
        let leaveHomeTime = trainDeparture
            .addingTimeInterval(TimeInterval(-(settings.walkingMinutesToStation + safetyBufferMinutes) * 60))

        // Fetch service status for both lines
        let lineIds = [settings.homeLineId, settings.officeLineId].filter { !$0.isEmpty }
        let lineStatuses = try await tflService.fetchLineStatus(for: lineIds)

        return CommuteResult(
            leaveHomeTime: leaveHomeTime,
            trainDepartureAtHomeStation: trainDeparture,
            trainArrivalAtOfficeStation: trainArrival,
            journeyDurationMinutes: journey.durationMinutes,
            numberOfStops: numberOfStops,
            serviceStatus: resolveServiceStatus(from: lineStatuses),
            dayLabel: dayLabel(for: commuteDate)
        )
    }

    // MARK: - Helpers

    /// Returns the soonest upcoming date that falls on one of the user's office days.
    func nextCommuteDate(from settings: UserSettings) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun … 7=Sat

        let officeDayValues = Set(settings.officeDays.map { $0.rawValue })
        guard !officeDayValues.isEmpty else { return today }

        for offset in 0...6 {
            let candidateWeekday = ((todayWeekday - 1 + offset) % 7) + 1
            if officeDayValues.contains(candidateWeekday) {
                return calendar.date(byAdding: .day, value: offset, to: today) ?? today
            }
        }
        return today
    }

    func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date)    { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return "Upcoming \(formatter.string(from: date))"
    }

    // MARK: - Private

    /// Parses TFL date strings, which may or may not carry timezone info.
    /// TFL typically returns local London time without a timezone suffix,
    /// e.g. "2026-01-23T08:19:00". Standard ISO8601DateFormatter requires
    /// a timezone and returns nil for such strings, so we fall back to a
    /// custom formatter locked to Europe/London.
    private static func parseTFLDate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: string) { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/London")
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZ"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }

    private func applyTime(_ time: Date, to date: Date) -> Date {
        let cal = Calendar.current
        let timeComponents = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(
            bySettingHour: timeComponents.hour ?? 9,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
    }

    private func resolveServiceStatus(from lines: [TFLLine]) -> ServiceStatus {
        for line in lines {
            let status = (line.lineStatuses?.first?.statusSeverityDescription ?? "").lowercased()
            if status.contains("severe") { return .severeDelays(line.serviceStatus) }
        }
        for line in lines {
            let status = (line.lineStatuses?.first?.statusSeverityDescription ?? "").lowercased()
            if status.contains("minor") || status.contains("delay") {
                return .minorDelays(line.serviceStatus)
            }
        }
        return .goodService
    }
}
