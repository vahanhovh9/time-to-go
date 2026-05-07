import Foundation

enum OutboundDestinationType: String, Codable {
    case home
    case otherPlace
}

/// All user preferences collected during onboarding.
/// Stored to and loaded from UserDefaults as JSON.
struct UserSettings: Codable {

    // MARK: - Home

    var homeStationId: String = ""
    var homeStationName: String = ""
    var homeStationLines: [TFLLineRef] = []
    var walkingMinutesToStation: Int = 5

    // MARK: - Office

    var officeStationId: String = ""
    var officeStationName: String = ""
    var officeStationLines: [TFLLineRef] = []
    var walkingMinutesToOffice: Int = 5

    // MARK: - Computed line helpers

    var homeLineId: String { homeStationLines.first?.id ?? "" }
    var homeLineIds: [String] { homeStationLines.map { $0.id } }
    var officeLineId: String { officeStationLines.first?.id ?? "" }
    var officeLineIds: [String] { officeStationLines.map { $0.id } }

    // MARK: - Inbound schedule

    var arrivalTime: Date = {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    var officeDays: [Weekday] = []

    // MARK: - Inbound notification

    var notificationTime: Date = {
        Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    }()

    // MARK: - Outbound (§12.7)

    var outboundEnabled: Bool = false
    var outboundDestinationType: OutboundDestinationType = .home

    /// Station the user is travelling to after work.
    var outboundDestinationStationId: String = ""
    var outboundDestinationStationName: String = ""
    var outboundDestinationStationLines: [TFLLineRef] = []

    /// Walk time from the destination station to the destination, in minutes.
    var outboundWalkingTimeFromStation: Int = 5

    /// When the user needs to arrive at the outbound destination.
    var outboundArrivalTime: Date = {
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    var outboundNotificationDays: [Weekday] = []

    var outboundNotificationTime: Date = {
        Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    // MARK: - Computed outbound helpers

    var outboundLineIds: [String] {
        let dest = outboundDestinationStationLines.map { $0.id }
        let office = officeStationLines.map { $0.id }
        return Array(Set(dest + office))
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case homeStationId, homeStationName, homeStationLines, walkingMinutesToStation
        case officeStationId, officeStationName, officeStationLines, walkingMinutesToOffice
        case arrivalTime, officeDays, notificationTime
        case outboundEnabled, outboundDestinationType
        case outboundDestinationStationId, outboundDestinationStationName, outboundDestinationStationLines
        case outboundWalkingTimeFromStation
        case outboundArrivalTime, outboundNotificationDays, outboundNotificationTime
        // Legacy keys (pre-outbound builds) — values ignored, keys kept to avoid decode errors
        case legacyHomeLineId   = "homeLineId"
        case legacyOfficeLineId = "officeLineId"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        homeStationId           = (try? c.decode(String.self,       forKey: .homeStationId))           ?? ""
        homeStationName         = (try? c.decode(String.self,       forKey: .homeStationName))         ?? ""
        walkingMinutesToStation = (try? c.decode(Int.self,          forKey: .walkingMinutesToStation)) ?? 5

        officeStationId         = (try? c.decode(String.self,       forKey: .officeStationId))         ?? ""
        officeStationName       = (try? c.decode(String.self,       forKey: .officeStationName))       ?? ""
        walkingMinutesToOffice  = (try? c.decode(Int.self,          forKey: .walkingMinutesToOffice))  ?? 5

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

        arrivalTime      = (try? c.decode(Date.self,      forKey: .arrivalTime))      ?? Calendar.current.date(bySettingHour: 9,  minute: 0,  second: 0, of: Date()) ?? Date()
        officeDays       = (try? c.decode([Weekday].self, forKey: .officeDays))       ?? []
        notificationTime = (try? c.decode(Date.self,      forKey: .notificationTime)) ?? Calendar.current.date(bySettingHour: 7,  minute: 30, second: 0, of: Date()) ?? Date()

        outboundEnabled             = (try? c.decode(Bool.self,                     forKey: .outboundEnabled))             ?? false
        outboundDestinationType     = (try? c.decode(OutboundDestinationType.self,  forKey: .outboundDestinationType))     ?? .home
        outboundDestinationStationId   = (try? c.decode(String.self,    forKey: .outboundDestinationStationId))   ?? ""
        outboundDestinationStationName = (try? c.decode(String.self,    forKey: .outboundDestinationStationName)) ?? ""
        outboundDestinationStationLines = (try? c.decode([TFLLineRef].self, forKey: .outboundDestinationStationLines)) ?? []
        outboundWalkingTimeFromStation  = (try? c.decode(Int.self,      forKey: .outboundWalkingTimeFromStation))  ?? 5
        outboundArrivalTime         = (try? c.decode(Date.self,         forKey: .outboundArrivalTime))         ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        outboundNotificationDays    = (try? c.decode([Weekday].self,    forKey: .outboundNotificationDays))    ?? []
        outboundNotificationTime    = (try? c.decode(Date.self,         forKey: .outboundNotificationTime))    ?? Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(homeStationId,            forKey: .homeStationId)
        try c.encode(homeStationName,          forKey: .homeStationName)
        try c.encode(homeStationLines,         forKey: .homeStationLines)
        try c.encode(walkingMinutesToStation,  forKey: .walkingMinutesToStation)
        try c.encode(officeStationId,          forKey: .officeStationId)
        try c.encode(officeStationName,        forKey: .officeStationName)
        try c.encode(officeStationLines,       forKey: .officeStationLines)
        try c.encode(walkingMinutesToOffice,   forKey: .walkingMinutesToOffice)
        try c.encode(arrivalTime,              forKey: .arrivalTime)
        try c.encode(officeDays,               forKey: .officeDays)
        try c.encode(notificationTime,         forKey: .notificationTime)
        try c.encode(outboundEnabled,                  forKey: .outboundEnabled)
        try c.encode(outboundDestinationType,          forKey: .outboundDestinationType)
        try c.encode(outboundDestinationStationId,     forKey: .outboundDestinationStationId)
        try c.encode(outboundDestinationStationName,   forKey: .outboundDestinationStationName)
        try c.encode(outboundDestinationStationLines,  forKey: .outboundDestinationStationLines)
        try c.encode(outboundWalkingTimeFromStation,   forKey: .outboundWalkingTimeFromStation)
        try c.encode(outboundArrivalTime,              forKey: .outboundArrivalTime)
        try c.encode(outboundNotificationDays,         forKey: .outboundNotificationDays)
        try c.encode(outboundNotificationTime,         forKey: .outboundNotificationTime)
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
