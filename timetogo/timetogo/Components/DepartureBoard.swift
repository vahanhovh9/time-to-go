import SwiftUI

/// "Toward Old Street / Updated live. Provided by TFL" card listing live departures.
struct DepartureBoard: View {
    var title: String
    var entries: [ScheduleEntry]
    var isLoading: Bool
    var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .typography(.h3)
                    .foregroundColor(.black)
                Text("Updated live. Provided by TFL")
                    .typography(.footnote)
                    .foregroundColor(.grey30)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Counts down between refreshes and drops trains once they've gone.
            TimelineView(.periodic(from: .now, by: 15)) { timeline in
                let upcoming = entries.filter { $0.expectedArrival > timeline.date.addingTimeInterval(-30) }
                VStack(spacing: 0) {
                    if isLoading && upcoming.isEmpty {
                        message { ProgressView().tint(.black) }
                    } else if let errorMessage, upcoming.isEmpty {
                        message { Text(errorMessage) }
                    } else if upcoming.isEmpty {
                        message { Text("No upcoming trains found in your direction right now.") }
                    } else {
                        ForEach(upcoming) { DepartureRow(entry: $0, now: timeline.date) }
                    }
                }
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.smallBlock)
                .stroke(Color.grey10, lineWidth: 1)
        )
    }

    private func message<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .typography(.main)
            .foregroundColor(.grey30)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .overlay(alignment: .top) { Rectangle().fill(Color.grey10).frame(height: 1) }
    }
}

private struct DepartureRow: View {
    let entry: ScheduleEntry
    let now: Date

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(Self.timeFormatter.string(from: entry.expectedArrival))
                    .typography(.large)
                    .foregroundColor(.grey50)
                    .frame(minWidth: 65, alignment: .leading)
                    .fixedSize()

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.towards.isEmpty ? entry.destinationName : entry.towards)
                        .typography(.large)
                        .foregroundColor(.grey50)
                    Text(entry.platformName)
                        .scaledFont(size: 11, weight: .medium)
                        .tracking(-0.5)
                        .foregroundColor(.grey30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(minutesText)
                .typography(.small)
                .foregroundColor(.grey50)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .frame(minWidth: 63, minHeight: 20)
                .background(Color.grey10)
                .clipShape(RoundedRectangle(cornerRadius: Radius.element))
                // Centres the chip on the time's first line, as in Figma.
                .padding(.top, 2)
        }
        .padding(.top, 16)
        .padding(.bottom, 20)
        .overlay(alignment: .top) { Rectangle().fill(Color.grey10).frame(height: 1) }
    }

    private var minutesText: String {
        let minutes = Int(entry.expectedArrival.timeIntervalSince(now) / 60)
        switch minutes {
        case ...0: return "Due"
        case 1:    return "1 min"
        default:   return "\(minutes) mins"
        }
    }
}
