import Foundation

/// All user preferences collected during onboarding.
/// Stored to and loaded from UserDefaults as JSON.
struct UserSettings: Codable {

    // MARK: - Home

    /// TFL line ID, e.g. "northern"
    var homeLineId: String = ""
    /// naptanId of the home station, e.g. "940GZZLUWSP"
    var homeStationId: String = ""
    /// Human-readable name shown in the UI, e.g. "Woodside Park Underground Station"
    var homeStationName: String = ""
    /// Walking time from home to the station, in minutes.
    var walkingMinutesToStation: Int = 5

    // MARK: - Office

    /// TFL line ID, e.g. "northern"
    var officeLineId: String = ""
    /// naptanId of the office station
    var officeStationId: String = ""
    /// Human-readable name shown in the UI
    var officeStationName: String = ""
    /// Walking time from the office station to the office, in minutes.
    var walkingMinutesToOffice: Int = 5

    // MARK: - Schedule

    /// Target arrival time at the office (only hour/minute components are used).
    var arrivalTime: Date = {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    /// Days of the week the user commutes.
    var officeDays: [Weekday] = []

    // MARK: - Notifications

    /// Time at which the "leave home" push notification should fire.
    var notificationTime: Date = {
        Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    }()

    // MARK: - Persistence

    private static let storageKey = "com.timetogo.userSettings"

    static func load() -> UserSettings? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(UserSettings.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
