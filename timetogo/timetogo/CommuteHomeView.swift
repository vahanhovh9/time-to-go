import SwiftUI

/// Which leg of the commute a home screen shows.
enum CommuteDirection {
    /// "To office": home → office.
    case toOffice
    /// "Back home": office → home (or the other outbound destination).
    case backHome
}

/// Commute home screen: journey + leave time over the illustrated header,
/// then the live departure board for the boarding station.
struct CommuteHomeView: View {
    let direction: CommuteDirection
    @ObservedObject var viewModel: MainViewModel
    @StateObject private var schedule = ScheduleReviewViewModel()
    /// True once the header has scrolled up under the status bar.
    @State private var isScrolled = false

    /// Height of the header below the status bar (416pt design frame minus 47pt status bar).
    private let headerHeight: CGFloat = 369

    var body: some View {
        GeometryReader { geo in
            content(topInset: geo.safeAreaInsets.top)
        }
    }

    private func content(topInset: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                header(topInset: topInset)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                DepartureBoard(
                    title: "Toward \(alightingStation)",
                    entries: schedule.entries,
                    isLoading: schedule.isLoading || isLoading,
                    errorMessage: schedule.errorMessage
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .coordinateSpace(name: Self.scrollSpace)
        .onPreferenceChange(HeaderOffsetKey.self) { minY in
            isScrolled = minY < -4
        }
        // Run the yellow header up behind the status bar; the header pads its own content.
        .ignoresSafeArea(edges: .top)
        .background(Color.white.ignoresSafeArea())
        .overlay(alignment: .top) {
            // Status-bar backdrop so scrolled content doesn't collide with the clock.
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: topInset)
                .opacity(isScrolled ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isScrolled)
                .allowsHitTesting(false)
        }
        .refreshable {
            switch direction {
            case .toOffice: await viewModel.refreshInbound()
            case .backHome: await viewModel.refreshOutbound()
            }
            if let ctx = scheduleContext { schedule.load(context: ctx) }
        }
        .task(id: scheduleContext) {
            if let ctx = scheduleContext { schedule.load(context: ctx) }
        }
        .onAppear {
            if direction == .backHome, viewModel.outboundResult == nil {
                viewModel.loadOutbound()
            }
        }
    }

    // MARK: - Header

    private func header(topInset: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            JourneyStops(
                title: journeyTitle,
                startLabel: startLabel,
                boardingStation: boardingStation,
                alightingStation: alightingStation,
                endLabel: endLabel
            )
            .padding(.leading, 26)
            .padding(.top, 14)

            LeaveTimeCard(
                caption: leaveCaption,
                time: leaveTimeText,
                status: result?.serviceStatus
            )
            .padding(.horizontal, 20)
            .padding(.top, 177)
        }
        .padding(.top, topInset)
        .frame(maxWidth: .infinity, minHeight: headerHeight + topInset, alignment: .topLeading)
        .background(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                Color(hex: "FFF9C0")
                Image(headerImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .clipped()
                Rectangle()
                    .fill(Color(hex: "F3EEB9"))
                    .frame(height: 3)
                MovingTrain(leftToRight: direction == .toOffice)
            }
        }
        // Yellow above the header fills the pull-to-refresh overscroll and scrolls with it.
        .background(alignment: .top) {
            Color(hex: "FFF9C0")
                .frame(height: 1000)
                .offset(y: -1000)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: HeaderOffsetKey.self,
                    value: geo.frame(in: .named(Self.scrollSpace)).minY
                )
            }
        )
    }

    private static let scrollSpace = "commuteHomeScroll"

    // MARK: - Direction-specific data

    private var result: CommuteResult? {
        direction == .toOffice ? viewModel.commuteResult : viewModel.outboundResult
    }

    private var isLoading: Bool {
        direction == .toOffice ? viewModel.isLoading : viewModel.isLoadingOutbound
    }

    private var errorMessage: String? {
        direction == .toOffice ? viewModel.errorMessage : viewModel.outboundErrorMessage
    }

    private var leaveTimeText: String {
        direction == .toOffice ? viewModel.leaveHomeTimeText : viewModel.leaveOfficeTimeText
    }

    private var scheduleContext: ScheduleReviewContext? {
        direction == .toOffice ? viewModel.inboundScheduleContext : viewModel.outboundScheduleContext
    }

    private var headerImage: String {
        direction == .toOffice ? "home-header-office" : "home-header-back"
    }

    private var journeyTitle: String {
        direction == .toOffice ? "Office journey" : "Back home journey"
    }

    private var startLabel: String {
        direction == .toOffice ? "Home" : "Office"
    }

    private var endLabel: String {
        switch direction {
        case .toOffice: return "Office"
        case .backHome: return viewModel.settings.outboundDestinationType == .home ? "Home" : "Destination"
        }
    }

    private var boardingStation: String {
        direction == .toOffice ? viewModel.homeStationDisplayName : viewModel.officeStationDisplayName
    }

    private var alightingStation: String {
        direction == .toOffice ? viewModel.officeStationDisplayName : viewModel.outboundDestinationDisplayName
    }

    /// "Today" → "LEAVE TODAY AT", "Upcoming Monday" → "LEAVE MONDAY AT".
    private var leaveCaption: String {
        let day = result?.dayLabel ?? "Today"
        let cleaned = day.replacingOccurrences(of: "Upcoming ", with: "")
        return "LEAVE \(cleaned.uppercased()) AT"
    }
}

// MARK: - Scroll tracking

private struct HeaderOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Moving train

/// Header train that runs like a tube train calling at a station: it brakes in from one
/// edge, dwells at its design position, accelerates out past the other edge, then
/// waits before the next run. With Reduce Motion it stays parked at the platform.
private struct MovingTrain: View {
    /// true: enters from the left, exits right. false: the mirror image.
    var leftToRight: Bool

    private enum Stop { case entry, platform, exit }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stop: Stop = .entry

    private let size = CGSize(width: 195, height: 23)
    /// Gap between the train and the screen edge it enters from, when stopped.
    private let platformInset: CGFloat = 69
    private let arriveSeconds: Double = 3.5
    private let dwellSeconds: Double = 2
    private let departSeconds: Double = 3.5
    private let pauseSeconds: Double = 2

    var body: some View {
        GeometryReader { geo in
            Image("header-train")
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
                .offset(x: x(for: reduceMotion ? .platform : stop, width: geo.size.width))
        }
        .frame(height: size.height)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { stop = .entry }
                // Let the reset render first, otherwise SwiftUI coalesces it with the arrival.
                try? await Task.sleep(for: .milliseconds(50))

                // Arrive: enter at speed, brake smoothly to a halt.
                withAnimation(.timingCurve(0.25, 0.6, 0.35, 1, duration: arriveSeconds)) { stop = .platform }
                try? await Task.sleep(for: .seconds(arriveSeconds + dwellSeconds))

                // Depart: pull away slowly, pick up speed through the right edge.
                withAnimation(.timingCurve(0.65, 0, 0.85, 0.55, duration: departSeconds)) { stop = .exit }
                try? await Task.sleep(for: .seconds(departSeconds + pauseSeconds))
            }
        }
    }

    private func x(for stop: Stop, width: CGFloat) -> CGFloat {
        let offLeft = -size.width
        let offRight = width
        switch stop {
        case .entry:    return leftToRight ? offLeft : offRight
        case .platform: return leftToRight ? platformInset : width - platformInset - size.width
        case .exit:     return leftToRight ? offRight : offLeft
        }
    }
}
