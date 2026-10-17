import SwiftUI

/// The whole journey, step by step: leave, walk, each train and change, arrive.
/// Opened from the Journey block's title on the To office / Back home screens.
struct JourneyDetailsView: View {
    let title: String
    let result: CommuteResult
    /// "Leave home" / "Leave the office".
    let startLabel: String
    /// "At the office" / "At home" / "At your destination".
    let endLabel: String
    let walkToStationMinutes: Int
    let walkFromStationMinutes: Int
    var onClose: () -> Void

    var body: some View {
        let steps = Self.steps(
            legs: result.legs,
            leave: result.leaveHomeTime,
            startLabel: startLabel,
            endLabel: endLabel,
            walkTo: walkToStationMinutes,
            walkFrom: walkFromStationMinutes
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(steps: steps)

                VStack(spacing: 0) {
                    ForEach(steps.indices, id: \.self) { i in
                        StepRow(
                            step: steps[i],
                            railAbove: i > 0 ? steps[i - 1].rail : nil,
                            railBelow: i < steps.count - 1 ? steps[i + 1].rail : nil
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Planned times. Live trains are on the departures board.")
                    Text("Powered by TfL Open Data")
                }
                .typography(.footnote)
                .foregroundColor(.grey30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Header

    private func header(steps: [Step]) -> some View {
        let trains = result.legs.filter { $0.kind == .train }.count
        let changes: String
        switch trains {
        case ...1: changes = "Direct"
        case 2:    changes = "1 change"
        default:   changes = "\(trains - 1) changes"
        }
        let end = steps.last?.time ?? result.trainArrivalAtOfficeStation
        let minutes = Int(end.timeIntervalSince(result.leaveHomeTime) / 60)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .typography(.h2)
                    .foregroundColor(.black)
                Spacer(minLength: 12)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(.grey50)
                        .frame(width: 32, height: 32)
                        .background(Color.grey10)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            Text(dayText)
                .typography(.main)
                .foregroundColor(.grey30)
            Text("\(Self.time(result.leaveHomeTime)) → \(Self.time(end)) · \(minutes) min · \(changes)")
                .typography(.large)
                .foregroundColor(.black)
        }
    }

    /// "Tomorrow · Sun 18 Oct", "Monday · Mon 19 Oct".
    private var dayText: String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        let day = result.dayLabel.replacingOccurrences(of: "Upcoming ", with: "")
        return "\(day) · \(f.string(from: result.leaveHomeTime))"
    }

    // MARK: - Steps

    /// Builds the timeline from TfL's legs plus the user's own walks at each end.
    static func steps(
        legs: [JourneyLeg],
        leave: Date,
        startLabel: String,
        endLabel: String,
        walkTo: Int,
        walkFrom: Int
    ) -> [Step] {
        guard let firstTrain = legs.first(where: { $0.kind == .train }) else { return [] }
        let onPlatform = leave.addingTimeInterval(TimeInterval(walkTo * 60))

        var steps: [Step] = [
            Step(time: leave, title: startLabel, kind: .place(.start)),
            Step(title: "Walk \(walkTo) min", kind: .walk(note: nil, isTight: false)),
            Step(time: onPlatform, title: firstTrain.from, kind: .place(.station), detail: "On the platform"),
        ]

        var here = firstTrain.from
        var readyAt = onPlatform
        var hasRidden = false
        for leg in legs {
            switch leg.kind {
            case .walk:
                // Walks before the first train are covered by the user's own walk time.
                guard hasRidden else { continue }
                steps.append(Step(title: "Walk to \(leg.to) · \(leg.minutes) min", kind: .walk(note: nil, isTight: false)))
                steps.append(Step(time: leg.arrival, title: leg.to, kind: .place(.station)))
                here = leg.to
                readyAt = leg.arrival

            case .train:
                if hasRidden {
                    let spare = Int(leg.departure.timeIntervalSince(readyAt) / 60)
                    steps.append(Step(
                        title: "Change to \(article(leg.lineName ?? "the next train"))",
                        kind: .walk(note: "\(max(0, spare)) min to change", isTight: spare < 3)
                    ))
                    if leg.from != here {
                        steps.append(Step(title: leg.from, kind: .place(.station)))
                    }
                }
                steps.append(Step(time: leg.departure, title: leg.lineName ?? "Train", kind: .ride(leg)))
                steps.append(Step(time: leg.arrival, title: leg.to, kind: .place(.station)))
                here = leg.to
                readyAt = leg.arrival
                hasRidden = true
            }
        }

        steps.append(Step(title: "Walk \(walkFrom) min", kind: .walk(note: nil, isTight: false)))
        steps.append(Step(
            time: readyAt.addingTimeInterval(TimeInterval(walkFrom * 60)),
            title: endLabel,
            kind: .place(.end)
        ))
        return steps
    }

    /// "Northern line" → "the Northern line"; "Thameslink" stays as it is.
    private static func article(_ lineName: String) -> String {
        lineName.hasSuffix(" line") || lineName == "DLR" ? "the \(lineName)" : lineName
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f.string(from: date)
    }
}

// MARK: - Step model

extension JourneyDetailsView {
    struct Step {
        enum Marker { case start, station, end }
        enum Kind {
            case place(Marker)
            case ride(JourneyLeg)
            case walk(note: String?, isTight: Bool)
        }

        var time: Date? = nil
        var title: String
        var kind: Kind
        var detail: String? = nil

        /// How the timeline line runs through this step; nil for places, which only
        /// continue the lines of their neighbours.
        var rail: Rail? {
            switch kind {
            case .place:          return nil
            case .ride(let leg):  return .solid(Color.tflLine(leg.lineId))
            case .walk:           return .dotted
            }
        }
    }

    enum Rail {
        case solid(Color)
        case dotted
    }
}

// MARK: - Row

private struct StepRow: View {
    let step: JourneyDetailsView.Step
    let railAbove: JourneyDetailsView.Rail?
    let railBelow: JourneyDetailsView.Rail?

    @State private var showsStops = false

    /// Same time column as the departures board, growing with the text size.
    @ScaledMetric(relativeTo: .subheadline) private var timeWidth: CGFloat = 65
    @ScaledMetric(relativeTo: .subheadline) private var markerY: CGFloat = 11
    private let railWidth: CGFloat = 16
    private let gap: CGFloat = 12

    var body: some View {
        HStack(alignment: .top, spacing: gap) {
            Text(step.time.map { JourneyDetailsView.time($0) } ?? "")
                .typography(.large)
                .foregroundColor(.grey50)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: timeWidth, alignment: .leading)

            Color.clear.frame(width: railWidth, height: 1)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // On the whole row, so the time lines up with the first line of text.
        .padding(.vertical, verticalPadding)
        // Drawn behind the row so the line always runs its full height.
        .background(alignment: .topLeading) {
            rail
                .frame(width: railWidth)
                .padding(.leading, timeWidth + gap)
        }
    }

    /// Places sit tight on the line; rides and walks get room around them.
    private var verticalPadding: CGFloat {
        if case .place = step.kind { return 0 }
        return 12
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch step.kind {
        case .place(let marker):
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .typography(marker == .station ? .h4 : .large)
                    .foregroundColor(.black)
                if let detail = step.detail {
                    Text(detail)
                        .typography(.main)
                        .foregroundColor(.grey30)
                }
            }
            .padding(.bottom, 4)

        case .ride(let leg):
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .typography(.h4)
                    .foregroundColor(.black)
                if let heading = leg.heading {
                    Text("to \(heading)")
                        .typography(.main)
                        .foregroundColor(.grey50)
                }
                if let status = leg.statusText {
                    Text(status)
                        .typography(.small)
                        .foregroundColor(Color(hex: "7A5500"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FFE7A3"))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                if !leg.stops.isEmpty {
                    stopsToggle(leg)
                }
            }

        case .walk(let note, let isTight):
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .typography(.main)
                    .foregroundColor(.grey50)
                if let note {
                    Text(note)
                        .typography(.small)
                        .foregroundColor(isTight ? Color(hex: "7A5500") : .grey30)
                }
            }
        }
    }

    private func stopsToggle(_ leg: JourneyLeg) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showsStops.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(leg.stops.count == 1 ? "1 stop" : "\(leg.stops.count) stops")
                    Text("· \(leg.minutes) min")
                    Image(systemName: showsStops ? "chevron.up" : "chevron.down")
                        .scaledFont(size: 11, weight: .semibold)
                }
                .typography(.main)
                .foregroundColor(.grey30)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showsStops ? "Hide stops" : "Show \(leg.stops.count) stops")

            if showsStops {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(leg.stops.enumerated()), id: \.offset) { _, stop in
                        Text(stop)
                            .typography(.main)
                            .foregroundColor(.grey50)
                    }
                }
                .padding(.leading, 4)
            }
        }
    }

    // MARK: Rail

    private var rail: some View {
        GeometryReader { geo in
            let x = geo.size.width / 2
            ZStack(alignment: .top) {
                switch step.kind {
                case .place(let marker):
                    if let railAbove {
                        line(railAbove, from: 0, to: markerY, x: x)
                    }
                    if let railBelow {
                        line(railBelow, from: markerY, to: geo.size.height, x: x)
                    }
                    markerView(marker)
                        .position(x: x, y: markerY)
                default:
                    if let own = step.rail {
                        line(own, from: 0, to: geo.size.height, x: x)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func line(_ rail: JourneyDetailsView.Rail, from top: CGFloat, to bottom: CGFloat, x: CGFloat) -> some View {
        let path = Path { p in
            p.move(to: CGPoint(x: x, y: top))
            p.addLine(to: CGPoint(x: x, y: bottom))
        }
        switch rail {
        case .solid(let color):
            path.stroke(color, lineWidth: 4)
        case .dotted:
            path.stroke(Color.grey30, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.5, 5]))
        }
    }

    @ViewBuilder
    private func markerView(_ marker: JourneyDetailsView.Step.Marker) -> some View {
        switch marker {
        case .start:
            Image("journey-home")
                .resizable()
                .frame(width: 12, height: 12)
                .background(Circle().fill(Color.white))
        case .station:
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        case .end:
            Image("journey-pin")
                .resizable()
                .frame(width: 14, height: 17)
        }
    }
}
