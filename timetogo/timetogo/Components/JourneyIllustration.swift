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
            let scale = journey.fillsFrame
                ? min(geo.size.width / journey.designSize.width, geo.size.height / journey.designSize.height)
                : min(geo.size.height / journey.designSize.height, 1)
            let size = CGSize(width: journey.designSize.width * scale, height: journey.designSize.height * scale)

            artwork
                .frame(width: size.width, height: size.height)
                .position(x: geo.size.width / 2, y: geo.size.height - size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: journey.fillsFrame ? nil : journey.designSize.height)
        // Artwork that fills its frame has nothing to crop, and its glow may leave the frame.
        .clipped(!journey.fillsFrame)
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
        /// Scales to the frame it's given, also above design size. For artwork made to the
        /// exact frame of `SetupStepLayout`; other artwork is wider and crops at the sides.
        let fillsFrame: Bool
        let glowColor: Color
        let glowCoreColor: Color
        /// The dotted route in artwork points, start → end of the glow. nil = no glow.
        let route: ((_ point: (CGFloat, CGFloat) -> CGPoint) -> Path)?

        init(
            imageName: String,
            designSize: CGSize,
            fillsFrame: Bool = false,
            glowColor: Color = .clear,
            glowCoreColor: Color = .clear,
            route: ((_ point: (CGFloat, CGFloat) -> CGPoint) -> Path)? = nil
        ) {
            self.imageName = imageName
            self.designSize = designSize
            self.fillsFrame = fillsFrame
            self.glowColor = glowColor
            self.glowCoreColor = glowCoreColor
            self.route = route
        }

        /// Back home setup: tube roundel → destination pin. Artwork 1206×789 @3x; the route
        /// follows Figma's "Vector 30" corners (drawn pin → tube there, reversed here), in
        /// artwork points.
        static let tubeToDestination = Journey(
            imageName: "back-home-tube",
            designSize: CGSize(width: 402, height: 263),
            fillsFrame: true,
            glowColor: Color(hex: "3ED3A7"),
            glowCoreColor: Color(hex: "A6F0D9")
        ) { p in
            var path = Path()
            path.move(to: p(52.3, 81))
            path.addLine(to: p(52.3, 52.5))
            path.addLine(to: p(132, 16.5))
            path.addLine(to: p(232, 48))
            path.addLine(to: p(321.5, 19.5))
            return path
        }

        /// Back home empty state: walking home from the office (no route). Artwork 1206×789 @3x.
        static let walkingHome = Journey(
            imageName: "back-home-empty",
            designSize: CGSize(width: 402, height: 263),
            fillsFrame: true
        )

        /// Back home setup, choosing a destination (no route). Artwork 1206×789 @3x.
        static let headingOut = Journey(
            imageName: "back-home-going",
            designSize: CGSize(width: 402, height: 263),
            fillsFrame: true
        )

        /// Step 3: at the desk (no route). Artwork 1206×789 @3x.
        static let atDesk = Journey(
            imageName: "setup-at-office",
            designSize: CGSize(width: 402, height: 263),
            fillsFrame: true
        )

        /// Step 1: home icon → tube roundel. Artwork 1206×789 @3x; the route follows
        /// Figma's "Vector 30" corners, in artwork points.
        static let homeToTube = Journey(
            imageName: "setup-walk-office",
            designSize: CGSize(width: 402, height: 263),
            fillsFrame: true,
            glowColor: Color(hex: "8789FF"),
            glowCoreColor: Color(hex: "B9BAFF")
        ) { p in
            var path = Path()
            path.move(to: p(74, 34))
            path.addLine(to: p(148.5, 2.2))
            path.addLine(to: p(246.8, 22.2))
            path.addLine(to: p(279.6, 72.4))
            path.addLine(to: p(309.5, 91))
            return path
        }

        /// Step 2: tube roundel → office pin. Artwork 1206×789 @3x; the route follows
        /// Figma's "Vector 30" corners (drawn pin → tube there, reversed here), in artwork points.
        static let tubeToOffice = Journey(
            imageName: "setup-walk-desk",
            designSize: CGSize(width: 402, height: 263),
            fillsFrame: true,
            glowColor: Color(hex: "3ED3A7"),
            glowCoreColor: Color(hex: "A6F0D9")
        ) { p in
            var path = Path()
            path.move(to: p(52.3, 81))
            path.addLine(to: p(52.3, 23.5))
            path.addLine(to: p(137.8, 2.5))
            path.addLine(to: p(216.5, 28))
            path.addLine(to: p(316.5, 18.5))
            return path
        }
    }
}

private extension View {
    @ViewBuilder
    func clipped(_ isClipped: Bool) -> some View {
        if isClipped { clipped() } else { self }
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
