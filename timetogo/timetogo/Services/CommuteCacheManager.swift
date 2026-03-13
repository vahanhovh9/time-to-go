import Foundation

// MARK: - Cached payload (Codable for UserDefaults)

/// Persisted representation of a CommuteResult.
/// Stored alongside the raw timestamp so validity can be checked offline.
struct CachedCommuteResult: Codable {
    let leaveHomeTime: Date
    let trainDepartureAtHomeStation: Date
    let trainArrivalAtOfficeStation: Date
    let journeyDurationMinutes: Int
    let numberOfStops: Int
    let serviceStatusText: String
    let dayLabel: String
    /// The calendar day this result belongs to (time stripped to midnight).
    let commuteDate: Date
    /// When CommuteCalculationService produced this result.
    let timestamp: Date
    /// §11.7: Marked true when a real leave-time notification has been scheduled.
    /// Prevents auto-recalculation while the user is in the same commute window.
    var isActive: Bool
}

// MARK: - Manager

/// §11.6 Cache rules: same commute date + not older than 24 hours = valid.
///
/// Trust-first contract (§11.5):
///   • `load(for:)` returns a result ONLY when it is both same-day AND within 24 h.
///   • Notifications may ONLY use data obtained via `load(for:)`.
///   • `fallback(for:)` returns any same-day entry regardless of age and is reserved
///     exclusively for in-app display with a staleness indicator. It MUST NOT be used
///     to populate notification content.
final class CommuteCacheManager {

    private let storageKey   = "com.timetogo.commuteCache"
    private let validityHours: Double = 24

    // MARK: - Save

    /// Persist a freshly calculated result for `date`.
    func save(_ result: CommuteResult, for date: Date) {
        let cached = CachedCommuteResult(
            leaveHomeTime:               result.leaveHomeTime,
            trainDepartureAtHomeStation: result.trainDepartureAtHomeStation,
            trainArrivalAtOfficeStation: result.trainArrivalAtOfficeStation,
            journeyDurationMinutes:      result.journeyDurationMinutes,
            numberOfStops:               result.numberOfStops,
            serviceStatusText:           result.serviceStatus.displayText,
            dayLabel:                    result.dayLabel,
            commuteDate:                 Calendar.current.startOfDay(for: date),
            timestamp:                   Date(),
            isActive:                    false
        )
        guard let data = try? JSONEncoder().encode(cached) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Load (trust-first: fresh only)

    /// Returns a validated cache entry for `date`.
    /// Returns nil if the entry is absent, belongs to a different day, or is older than 24 h.
    /// This is the ONLY source for notification content (§11.5, §11.6).
    func load(for date: Date) -> CachedCommuteResult? {
        guard let cached = loadRaw(), isValid(cached, for: date) else { return nil }
        return cached
    }

    // MARK: - §11.7 Active-result locking

    /// Mark the current cache entry as the active commute result.
    /// Call this immediately after scheduling a real leave-time notification (§11.7)
    /// so that `hasActiveResult(for:)` returns true when the user opens the app.
    func markAsActive() {
        guard var cached = loadRaw() else { return }
        cached.isActive = true
        guard let data = try? JSONEncoder().encode(cached) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    /// §11.7: True when a real leave-time notification has been committed for `date`.
    /// The main flow MUST NOT auto-recalculate while this is true.
    /// Only a manual refresh, date change, or settings change may override.
    func hasActiveResult(for date: Date) -> Bool {
        guard let cached = loadRaw(), cached.isActive else { return false }
        return Calendar.current.isDate(cached.commuteDate, inSameDayAs: date)
    }

    // MARK: - In-app staleness fallback (§11.6 — NOT for notifications)

    /// Returns any same-day cache entry regardless of age.
    ///
    /// Use ONLY for in-app display when you want to show the last known value
    /// with a clear staleness indicator. NEVER use for notification content.
    func fallback(for date: Date) -> CachedCommuteResult? {
        guard let cached = loadRaw() else { return nil }
        guard Calendar.current.isDate(cached.commuteDate, inSameDayAs: date) else { return nil }
        return cached
    }

    // MARK: - Validity helpers

    /// True if a fresh (same-day + <24 h) entry exists for `date`.
    func isValid(for date: Date) -> Bool {
        guard let cached = loadRaw() else { return false }
        return isValid(cached, for: date)
    }

    /// True if the entry is same-day but older than 24 h.
    /// Use to drive a staleness indicator in the UI (§11.6).
    func isStale(for date: Date) -> Bool {
        guard let cached = loadRaw() else { return false }
        guard Calendar.current.isDate(cached.commuteDate, inSameDayAs: date) else { return false }
        let ageHours = Date().timeIntervalSince(cached.timestamp) / 3600
        return ageHours >= validityHours
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Private

    private func loadRaw() -> CachedCommuteResult? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(CachedCommuteResult.self, from: data)
    }

    private func isValid(_ cached: CachedCommuteResult, for date: Date) -> Bool {
        guard Calendar.current.isDate(cached.commuteDate, inSameDayAs: date) else { return false }
        let ageHours = Date().timeIntervalSince(cached.timestamp) / 3600
        return ageHours < validityHours
    }
}
