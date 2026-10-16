import Foundation

/// Plain-language messages for errors shown on screen. Technical detail stays out of the UI.
nonisolated enum UserFacingError {
    static func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "No internet connection. Pull down to try again."
            case .timedOut, .cannotFindHost, .cannotConnectToHost:
                return "TfL isn't responding right now. Pull down to try again."
            default:
                break
            }
        }
        if let tfl = error as? TFLError {
            switch tfl {
            case .noJourneyFound:
                return "TfL couldn't find a tube route between your stations. Check them in Settings."
            case .badResponse, .invalidURL, .decodingFailed:
                return "Couldn't get your journey from TfL. Pull down to try again."
            }
        }
        if let schedule = error as? ScheduleError {
            switch schedule {
            case .directionUnknown:
                return "Live departures aren't available for this route yet."
            case .noMatchingPlatformData:
                return "No departures found right now. Pull down to refresh."
            }
        }
        return "Something went wrong. Pull down to try again."
    }
}
