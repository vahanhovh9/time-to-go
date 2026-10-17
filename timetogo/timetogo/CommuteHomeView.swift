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
    @State private var showsJourneyDetails = false

    /// Space between the leave-time card and the bottom of the yellow header.
    private let cardBottomGap: CGFloat = 50

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
                        .typography(.main)
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
        .sheet(isPresented: $showsJourneyDetails) {
            if let result {
                JourneyDetailsView(
                    title: journeyTitle,
                    result: result,
                    startLabel: direction == .toOffice ? "Leave home" : "Leave the office",
                    endLabel: endArrivalLabel,
                    walkToStationMinutes: direction == .toOffice
                        ? viewModel.settings.walkingMinutesToStation
                        : viewModel.settings.walkingMinutesToOffice,
                    walkFromStationMinutes: direction == .toOffice
                        ? viewModel.settings.walkingMinutesToOffice
                        : viewModel.settings.effectiveOutboundWalkingTime,
                    onClose: { showsJourneyDetails = false }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Header

    private func header(topInset: CGFloat) -> some View {
        // Stacked rather than overlaid so long (wrapping) station names push the card down.
        VStack(alignment: .leading, spacing: 24) {
            JourneyStops(
                title: journeyTitle,
                startLabel: startLabel,
                boardingStation: boardingStation,
                alightingStation: alightingStation,
                endLabel: endLabel,
                // Only once the journey is planned (a cache restore has no legs).
                onShowDetails: (result?.legs.isEmpty ?? true) ? nil : { showsJourneyDetails = true }
            )
            .padding(.leading, 26)
            .padding(.top, 14)

            LeaveTimeCard(
                caption: leaveCaption,
                time: leaveTimeText,
                status: result?.serviceStatus
            )
            .anchorPreference(key: LeaveCardBoundsKey.self, value: .bounds) { $0 }
            .padding(.horizontal, 20)
            // The header ends a fixed 50pt below the card, however tall the card renders.
            .padding(.bottom, cardBottomGap)
        }
        .padding(.top, topInset)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .backgroundPreferenceValue(LeaveCardBoundsKey.self) { cardBounds in
            GeometryReader { geo in
                let scale = geo.size.width / Self.headerArtSize.width
                let cardTop = cardBounds.map { geo[$0].minY } ?? Self.figmaCardTop
                // Width-fitted and pinned to the card as in Figma, so the skyline ends just
                // above the card whatever the status bar height or station-name wrapping.
                Image(headerImage)
                    .resizable()
                    .frame(width: geo.size.width, height: Self.headerArtSize.height * scale)
                    // Drop the 3pt divider baked into the export's bottom edge; the header draws its own.
                    .frame(height: (Self.headerArtSize.height - 3) * scale, alignment: .top)
                    .clipped()
                    .offset(y: cardTop - Self.figmaCardTop * scale)
            }
            .clipped()
        }
        .background(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                Color(hex: "FFF9C0")
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
    /// Header artwork size in points (the @3x export ÷ 3).
    private static let headerArtSize = CGSize(width: 402, height: 443)
    /// Top of the leave-time card within the artwork, from the Figma frame.
    private static let figmaCardTop: CGFloat = 249

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

    /// Last step of the journey page: "At the office", "At home", "At your destination".
    private var endArrivalLabel: String {
        switch direction {
        case .toOffice: return "At the office"
        case .backHome: return viewModel.settings.outboundDestinationType == .home ? "At home" : "At your destination"
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

private struct LeaveCardBoundsKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
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
    /// Gap between the train and the screen edge it enters from, when stopped (per Figma).
    private var platformInset: CGFloat { leftToRight ? 69 : 36 }
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
