import SwiftUI

/// Success page (Figma "Success page"): illustrated yellow top, white panel with
/// the confirmation, the next commute, and the two actions.
/// Used at the end of setup and of the Back home setup.
struct SetupSuccessView: View {
    var title = "🎉 Awesome, all set up! 🎉"
    var message = "Any time you open TimeToGo, it shows when to leave next."
    /// The next office day the app will plan for.
    var nextCommute: Date
    /// The user's chosen office arrival time.
    var arrivalTime: Date
    var onAllDone: () -> Void
    var onChangeSettings: () -> Void

    /// Artwork size in points (1323×1167 @3x export).
    private let artworkSize = CGSize(width: 441, height: 389)
    /// Height of the yellow area in the 874pt-tall Figma frame (status bar included).
    private let designHeaderHeight: CGFloat = 330

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let fullHeight = geo.size.height + topInset + geo.safeAreaInsets.bottom
            // Same share of the screen as the design (330 of 874), so small phones keep room for the panel.
            let headerHeight = min(designHeaderHeight, fullHeight * designHeaderHeight / 874)

            VStack(spacing: 0) {
                header(height: headerHeight)
                panel
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Color.white)
    }

    // MARK: - Header

    private func header(height: CGFloat) -> some View {
        let scale = min(height / designHeaderHeight, 1)
        return Color(hex: "FFF9C0")
            .frame(height: height)
            .overlay(alignment: .bottom) {
                // The artwork's bottom sits on the panel; its top (confetti) crops, as in Figma,
                // and it's nudged 19.5pt left of centre like the design frame.
                Image("setup-success")
                    .resizable()
                    .frame(width: artworkSize.width * scale, height: artworkSize.height * scale)
                    .offset(x: -19.5 * scale)
                    .accessibilityHidden(true)
            }
            .clipped()
    }

    // MARK: - Panel

    private var panel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text(title)
                    .typography(.h2)
                    .foregroundColor(.black)
                Text(message)
                    .typography(.large)
                    .foregroundColor(.grey50)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 46)

            Spacer(minLength: 24)

            VStack(spacing: 8) {
                Text("Next commute")
                    .typography(.h3)
                    .foregroundColor(.black)
                Text(nextCommuteText)
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundColor(.grey50)
            }
            .multilineTextAlignment(.center)

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                CustomButton(title: "All done", style: .filled, action: onAllDone)
                CustomButton(title: "Change your settings", style: .text, action: onChangeSettings)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    /// "Tuesday 15th July, arrive 9:00 am"
    private var nextCommuteText: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: nextCommute)
        let suffix: String
        switch day % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        let weekday = Self.weekdayFormatter.string(from: nextCommute)
        let month = Self.monthFormatter.string(from: nextCommute)
        let time = Self.timeFormatter.string(from: arrivalTime)
        return "\(weekday) \(day)\(suffix) \(month), arrive \(time)"
    }

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f
    }()
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM"; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; f.amSymbol = "am"; f.pmSymbol = "pm"; return f
    }()
}

#Preview {
    SetupSuccessView(
        nextCommute: Date(),
        arrivalTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        onAllDone: {},
        onChangeSettings: {}
    )
}
