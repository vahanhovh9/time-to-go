import SwiftUI

/// Setup artwork with a glow that travels along the artwork's dotted path
/// (e.g. home → tube), fades out, waits, and runs again. With Reduce Motion the glow is not shown.
///
/// Sized by height so the figure is never cut top or bottom (legs included): full design
/// size when there's room, scaled down to fit when there isn't. Like the Figma frames,
/// the wide artwork may crop at the sides instead.
struct JourneyIllustration: View {
    let journey: Journey

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var isVisible = false

    private let travelSeconds: Double = 2.4
    private let fadeSeconds: Double = 0.35
    private let pauseSeconds: Double = 2

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.height / journey.designSize.height, 1)
            let size = CGSize(width: journey.designSize.width * scale, height: journey.designSize.height * scale)

            artwork
                .frame(width: size.width, height: size.height)
                .position(x: geo.size.width / 2, y: geo.size.height - size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: journey.designSize.height)
        .clipped()
        .accessibilityHidden(true)
        .task(id: reduceMotion) {
            guard !reduceMotion, journey.route != nil else { return }
            while !Task.isCancelled {
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) {
                    progress = 0
                    isVisible = true
                }
                // Let the reset render first, otherwise SwiftUI coalesces it with the run.
                try? await Task.sleep(for: .milliseconds(50))

                withAnimation(.easeInOut(duration: travelSeconds)) { progress = 1 }
                try? await Task.sleep(for: .seconds(travelSeconds))

                withAnimation(.easeOut(duration: fadeSeconds)) { isVisible = false }
                try? await Task.sleep(for: .seconds(fadeSeconds + pauseSeconds))
            }
        }
    }

    private var artwork: some View {
        Image(journey.imageName)
            .resizable()
            .overlay {
                if !reduceMotion, journey.route != nil {
                    glow
                }
            }
    }

    private var glow: some View {
        ZStack {
            // Soft halo
            GlowTrail(journey: journey, progress: progress)
                .stroke(journey.glowColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .blur(radius: 6)
                .opacity(0.7)
            // Bright core
            GlowTrail(journey: journey, progress: progress)
                .stroke(journey.glowCoreColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .shadow(color: journey.glowColor, radius: 3)
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(false)
    }
}

// MARK: - Journeys

extension JourneyIllustration {
    struct Journey {
        let imageName: String
        /// Artwork size in points (the @3x export ÷ 3).
        let designSize: CGSize
        let glowColor: Color
        let glowCoreColor: Color
        /// The dotted route in artwork points, start → end of the glow. nil = no glow.
        let route: ((_ point: (CGFloat, CGFloat) -> CGPoint) -> Path)?

        init(
            imageName: String,
            designSize: CGSize,
            glowColor: Color = .clear,
            glowCoreColor: Color = .clear,
            route: ((_ point: (CGFloat, CGFloat) -> CGPoint) -> Path)? = nil
        ) {
            self.imageName = imageName
            self.designSize = designSize
            self.glowColor = glowColor
            self.glowCoreColor = glowCoreColor
            self.route = route
        }

        /// Back home, other place: tube roundel (right) → destination pin (left).
        /// Artwork 1410×981 @3x; same Figma "Vector 30" as step 2, drawn tube → pin
        /// in this artwork, so it's used in its original order; it sits at (72, 39.5).
        static let tubeToDestination = Journey(
            imageName: "back-home-tube",
            designSize: CGSize(width: 470, height: 327),
            glowColor: Color(hex: "3ED3A7"),
            glowCoreColor: Color(hex: "A6F0D9")
        ) { p in
            let o = CGPoint(x: 72, y: 39.5)
            func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(x + o.x, y + o.y) }
            var path = Path()
            path.move(to: q(250, 1.00027))
            path.addLine(to: q(159.344, 34.4843))
            path.addCurve(to: q(155.058, 34.8352), control1: q(157.974, 34.9903), control2: q(156.492, 35.1116))
            path.addLine(to: q(58.8095, 16.2814))
            path.addCurve(to: q(56.8923, 16.3036), control1: q(58.1741, 16.1589), control2: q(57.5222, 16.1555))
            path.addCurve(to: q(29, 30.7046), control1: q(44.7767, 19.1511), control2: q(29, 30.7046))
            path.addLine(to: q(29, 57.0003))
            return path
        }

        /// Back home empty state: walking home from the office (no route). Artwork 537×373pt.
        static let walkingHome = Journey(
            imageName: "back-home-empty",
            designSize: CGSize(width: 537, height: 373)
        )

        /// Step 3: at the desk (no route). Artwork 1191×690 @3x.
        static let atDesk = Journey(
            imageName: "setup-at-office",
            designSize: CGSize(width: 397, height: 230)
        )

        /// Step 1: home pin → tube roundel. Artwork 1611×1119 @3x; the route is Figma's
        /// "Vector 30" in Group 21, which sits at (114.7, 10.7) inside the artwork.
        static let homeToTube = Journey(
            imageName: "setup-walk-office",
            designSize: CGSize(width: 537, height: 373),
            glowColor: Color(hex: "8789FF"),
            glowCoreColor: Color(hex: "B9BAFF")
        ) { p in
            let o = CGPoint(x: 114.7, y: 10.7)
            func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(x + o.x, y + o.y) }
            var path = Path()
            path.move(to: q(30.963, 46.6902))
            path.addLine(to: q(66.4038, 7.02848))
            path.addCurve(to: q(78.5984, 7.33942), control1: q(69.6937, 3.34678), control2: q(75.5005, 3.49484))
            path.addLine(to: q(114.345, 51.7003))
            path.addCurve(to: q(118.501, 53.5722), control1: q(115.353, 52.952), control2: q(116.895, 53.6394))
            path.addCurve(to: q(170.034, 59.1409), control1: q(133.748, 52.9348), control2: q(161.861, 53.2613))
            path.addCurve(to: q(213.301, 87.1551), control1: q(178.687, 65.3663), control2: q(202.484, 80.4109))
            return path
        }

        /// Step 2: tube roundel → office pin. Artwork 1410×981 @3x; the route is Figma's
        /// "Vector 30" in Group 21 (drawn pin → tube there, reversed here), at (72.7, 30.8).
        static let tubeToOffice = Journey(
            imageName: "setup-walk-desk",
            designSize: CGSize(width: 470, height: 327),
            glowColor: Color(hex: "3ED3A7"),
            glowCoreColor: Color(hex: "A6F0D9")
        ) { p in
            let o = CGPoint(x: 72.7, y: 30.8)
            func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(x + o.x, y + o.y) }
            var path = Path()
            path.move(to: q(29, 57.0003))
            path.addLine(to: q(29, 30.7046))
            path.addCurve(to: q(56.8923, 16.3036), control1: q(29, 30.7046), control2: q(44.7767, 19.1511))
            path.addCurve(to: q(58.8095, 16.2814), control1: q(57.5222, 16.1555), control2: q(58.1741, 16.1589))
            path.addLine(to: q(155.058, 34.8352))
            path.addCurve(to: q(159.344, 34.4843), control1: q(156.492, 35.1116), control2: q(157.974, 34.9903))
            path.addLine(to: q(250, 1.00027))
            return path
        }
    }
}

/// Leading segment of the journey route, ending at `progress` (0…1).
private struct GlowTrail: Shape {
    let journey: JourneyIllustration.Journey
    var progress: CGFloat
    private let trailLength: CGFloat = 0.22

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let end = min(max(progress, 0), 1)
        let start = max(0, end - trailLength)
        guard end > start, let routeBuilder = journey.route else { return Path() }
        let sx = rect.width / journey.designSize.width
        let sy = rect.height / journey.designSize.height
        let route = routeBuilder { x, y in
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        return route.trimmedPath(from: start, to: end)
    }
}

#Preview {
    VStack {
        JourneyIllustration(journey: .homeToTube)
        JourneyIllustration(journey: .tubeToOffice).frame(height: 220)
    }
    .frame(width: 402)
}
