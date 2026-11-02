import SwiftUI

/// Success page (Figma "Success page"): the illustration across the top of the screen with
/// the confirmation card over its lower edge, showing the next commute.
/// Shown at the end of setup.
struct SetupSuccessView: View {
    /// The next office day the app will plan for.
    var nextCommute: Date
    /// The user's chosen office arrival time.
    var arrivalTime: Date
    var onAllDone: () -> Void

    /// Figma: the artwork, and where the card starts over it.
    private let artworkSize = CGSize(width: 402, height: 437)
    private let designCardTop: CGFloat = 419

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / artworkSize.width

            ZStack(alignment: .top) {
                Image("setup-success")
                    .resizable()
                    .frame(width: geo.size.width, height: artworkSize.height * scale)
                    .overlay { ConfettiSparkle(scale: scale) }
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    // Keeps the card at the design position; on short phones the card
                    // covers more of the artwork instead of cropping its text.
                    Color.clear
                        .frame(maxHeight: designCardTop * scale)
                        .layoutPriority(1)
                    card
                        .padding(.horizontal, 20)
                        // Figma: 30pt from the screen bottom.
                        .padding(.bottom, max(geo.safeAreaInsets.bottom - 4, 16))
                }
            }
            .ignoresSafeArea()
        }
        .background(Color.brightBackground.ignoresSafeArea())
    }

    // MARK: - Card

    private var card: some View {
        SetupCard {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("🎉 Awesome, all set up! 🎉")
                        .typography(.h2)
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Just open TimeToGo anytime to see exactly when to leave home ;)")
                        .typography(.large)
                        .foregroundColor(.grey40)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 4) {
                    Text("Next commute")
                        .scaledFont(size: 12, weight: .bold)
                        .tracking(-0.5)
                        .foregroundColor(.grey40)
                    Text(nextCommuteText)
                        .scaledFont(size: 14, weight: .medium)
                        .foregroundColor(.black)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brightBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer(minLength: 24)

            CustomButton(title: "All done", style: .filled, action: onAllDone)
        }
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

/// Makes the artwork's confetti twinkle: soft patches of the background colour fade in and
/// out over the pieces, each at its own pace, so they dim and brighten in turn.
/// Off with Reduce Motion, where the artwork stays as it is.
private struct ConfettiSparkle: View {
    var scale: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Centres of the confetti pieces in artwork points. None sit on the figure.
    private static let pieces: [CGPoint] = [
        (196, 31), (303, 51), (347, 65), (102, 61), (158, 67), (248, 70), (69, 94), (155, 95),
        (227, 94), (269, 92), (106, 111), (316, 106), (358, 110), (255, 122), (308, 132),
        (201, 132), (153, 145), (252, 148), (340, 161), (393, 152), (289, 183), (272, 204),
        (367, 199), (62, 220), (32, 247), (324, 229), (351, 228), (303, 247), (377, 268),
        (45, 307), (63, 348),
    ].map { CGPoint(x: $0.0, y: $0.1) }

    private let patchRadius: CGFloat = 24
    private let maxOpacity = 0.85

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { timeline in
                Canvas { context, _ in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let radius = patchRadius * scale
                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: 6 * scale))
                        for (index, piece) in Self.pieces.enumerated() {
                            // The golden angle spreads the pieces out of step with each other.
                            let phase = Double(index) * 2.399
                            let period = 2.6 + Double(index % 5) * 0.35
                            let wave = max(0, sin(time * 2 * .pi / period + phase))
                            let rect = CGRect(
                                x: piece.x * scale - radius,
                                y: piece.y * scale - radius,
                                width: radius * 2,
                                height: radius * 2
                            )
                            layer.fill(
                                Path(ellipseIn: rect),
                                with: .color(Color.brightBackground.opacity(wave * wave * maxOpacity))
                            )
                        }
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    SetupSuccessView(
        nextCommute: Date(),
        arrivalTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        onAllDone: {}
    )
}
