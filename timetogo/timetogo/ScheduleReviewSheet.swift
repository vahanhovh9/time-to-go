import SwiftUI

struct ScheduleReviewSheet: View {
    let context: ScheduleReviewContext
    @StateObject private var viewModel = ScheduleReviewViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(32)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.entries.isEmpty {
                    Text("No upcoming trains found in your direction right now.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(32)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.entries) { entry in
                        DepartureRow(entry: entry)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Toward \(context.destinationStationName)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: context) {
            viewModel.load(context: context)
        }
    }
}

private struct DepartureRow: View {
    let entry: ScheduleEntry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.destinationName)
                    .font(.system(size: 16, weight: .semibold))
                if !entry.towards.isEmpty {
                    Text(entry.towards)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Text(entry.platformName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(Self.timeFormatter.string(from: entry.expectedArrival))
                    .font(.system(size: 16, weight: .semibold))
                Text("\(entry.minutesUntilArrival) min")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(entry.lineName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
