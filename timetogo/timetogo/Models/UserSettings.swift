import Foundation

/// All user preferences collected during onboarding.
/// Stored to and loaded from UserDefaults as JSON.
struct UserSettings: Codable {

    // MARK: - Home

    /// naptanId of the home station, e.g. "940GZZLUWSP"
    var homeStationId: String = ""
    /// Human-readable name shown in the UI, e.g. "Woodside Park Underground Station"
    var homeStationName: String = ""
    /// All TFL lines serving the home station.
    var homeStationLines: [TFLLineRef] = []
    /// Walking time from home to the station, in minutes.
    var walkingMinutesToStation: Int = 5

    // MARK: - Office

    /// naptanId of the office station
    var officeStationId: String = ""
    /// Human-readable name shown in the UI
    var officeStationName: String = ""
    /// All TFL lines serving the office station.
    var officeStationLines: [TFLLineRef] = []
    /// Walking time from the office station to the office, in minutes.
    var walkingMinutesToOffice: Int = 5

    // MARK: - Computed line helpers (used by MainViewModel, CommuteCalculationService, etc.)

    /// Primary line ID — first line serving the home station.
    var homeLineId: String { homeStationLines.first?.id ?? "" }
    /// All line IDs for the home station (used for status checks).
    var homeLineIds: [String] { homeStationLines.map { $0.id } }

    /// Primary line ID — first line serving the office station.
    var officeLineId: String { officeStationLines.first?.id ?? "" }
    /// All line IDs for the office station (used for status checks).
    var officeLineIds: [String] { officeStationLines.map { $0.id } }

    // MARK: - Schedule

    /// Target arrival time at the office (only hour/minute components are used).
    var arrivalTime: Date = {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    /// Target arrival time at home for the evening commute (only hour/minute components are used).
    var homeArrivalTime: Date = {
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    /// Days of the week the user commutes.
    var officeDays: [Weekday] = []

    // MARK: - Notifications

    /// Time at which the "leave home" push notification should fire.
    var notificationTime: Date = {
        Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    }()

    /// Time at which the "leave office" push notification should fire.
    var homeNotificationTime: Date = {
        Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    // MARK: - Codable
    // Custom implementation to handle migration from the legacy single-lineId format.

    enum CodingKeys: String, CodingKey {
        case homeStationId, homeStationName, homeStationLines, walkingMinutesToStation
        case officeStationId, officeStationName, officeStationLines, walkingMinutesToOffice
        case arrivalTime, homeArrivalTime, officeDays, notificationTime, homeNotificationTime
        // Legacy keys present in settings saved before this version
        case legacyHomeLineId   = "homeLineId"
        case legacyOfficeLineId = "officeLineId"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        homeStationId   = (try? c.decode(String.self, forKey: .homeStationId))   ?? ""
        homeStationName = (try? c.decode(String.self, forKey: .homeStationName)) ?? ""
        walkingMinutesToStation = (try? c.decode(Int.self, forKey: .walkingMinutesToStation)) ?? 5

        officeStationId   = (try? c.decode(String.self, forKey: .officeStationId))   ?? ""
        officeStationName = (try? c.decode(String.self, forKey: .officeStationName)) ?? ""
        walkingMinutesToOffice = (try? c.decode(Int.self, forKey: .walkingMinutesToOffice)) ?? 5

        // Prefer new [TFLLineRef] format; fall back to legacy String for migration
        if let lines = try? c.decode([TFLLineRef].self, forKey: .homeStationLines), !lines.isEmpty {
            homeStationLines = lines
        } else if let oldId = try? c.decode(String.self, forKey: .legacyHomeLineId), !oldId.isEmpty {
            homeStationLines = [TFLLineRef(id: oldId, name: oldId)]
        } else {
            homeStationLines = []
        }

        if let lines = try? c.decode([TFLLineRef].self, forKey: .officeStationLines), !lines.isEmpty {
            officeStationLines = lines
        } else if let oldId = try? c.decode(String.self, forKey: .legacyOfficeLineId), !oldId.isEmpty {
            officeStationLines = [TFLLineRef(id: oldId, name: oldId)]
        } else {
            officeStationLines = []
        }

        arrivalTime          = (try? c.decode(Date.self,      forKey: .arrivalTime))          ?? Calendar.current.date(bySettingHour: 9,  minute: 0,  second: 0, of: Date()) ?? Date()
        homeArrivalTime      = (try? c.decode(Date.self,      forKey: .homeArrivalTime))      ?? Calendar.current.date(bySettingHour: 18, minute: 0,  second: 0, of: Date()) ?? Date()
        officeDays           = (try? c.decode([Weekday].self, forKey: .officeDays))           ?? []
        notificationTime     = (try? c.decode(Date.self,      forKey: .notificationTime))     ?? Calendar.current.date(bySettingHour: 7,  minute: 30, second: 0, of: Date()) ?? Date()
        homeNotificationTime = (try? c.decode(Date.self,      forKey: .homeNotificationTime)) ?? Calendar.current.date(bySettingHour: 16, minute: 0,  second: 0, of: Date()) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(homeStationId,           forKey: .homeStationId)
        try c.encode(homeStationName,         forKey: .homeStationName)
        try c.encode(homeStationLines,        forKey: .homeStationLines)
        try c.encode(walkingMinutesToStation, forKey: .walkingMinutesToStation)
        try c.encode(officeStationId,         forKey: .officeStationId)
        try c.encode(officeStationName,       forKey: .officeStationName)
        try c.encode(officeStationLines,      forKey: .officeStationLines)
        try c.encode(walkingMinutesToOffice,  forKey: .walkingMinutesToOffice)
        try c.encode(arrivalTime,             forKey: .arrivalTime)
        try c.encode(homeArrivalTime,         forKey: .homeArrivalTime)
        try c.encode(officeDays,              forKey: .officeDays)
        try c.encode(notificationTime,        forKey: .notificationTime)
        try c.encode(homeNotificationTime,    forKey: .homeNotificationTime)
    }

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
