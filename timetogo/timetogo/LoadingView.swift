import SwiftUI

/// Launch loading screen: the illustrated background with a train running along its
/// horizontal line. The train moves while the commute loads and reaches the end of the
/// line when it's ready; a quick load skips the screen entirely.
struct LoadingView: View {
    /// Checked every 0.1s: true once there's something to show (a result or an error).
    var isReady: () -> Bool
    /// Called when the screen should go. `animated` is false for a quick load.
    var onDone: (_ animated: Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0: train just off the left edge; 1: just off the right edge.
    @State private var progress: CGFloat = 0

    /// Ready within this time: go straight to the app, no train run.
    private let quickLoad: TimeInterval = 0.4
    /// Stop waiting after this long and show the app anyway (it shows its own errors).
    private let timeout: TimeInterval = 10
    /// While waiting, the train eases towards this point and slows down.
    private let waitingProgress: CGFloat = 0.55
    private let waitingSeconds: Double = 4
    private let finishSeconds: Double = 0.7

    /// Artwork size in points (the @3x export ÷ 3) and the top of its horizontal line.
    private let artSize = CGSize(width: 402, height: 874)
    private let lineTop: CGFloat = 626
    private let trainSize = CGSize(width: 256, height: 30)

    var body: some View {
        GeometryReader { geo in
            // Same scale-to-fill as the background, so the train stays on the line.
            let scale = max(geo.size.width / artSize.width, geo.size.height / artSize.height)
            let artTop = (geo.size.height - artSize.height * scale) / 2
            let travel = geo.size.width + trainSize.width

            ZStack(alignment: .topLeading) {
                Image("loading-background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                Image("loading-train")
                    .resizable()
                    .frame(width: trainSize.width, height: trainSize.height)
                    .offset(
                        x: -trainSize.width + travel * (reduceMotion ? 0.5 : progress),
                        // Wheels resting on the line.
                        y: artTop + lineTop * scale - trainSize.height + 1
                    )
            }
        }
        .ignoresSafeArea()
        .accessibilityElement()
        .accessibilityLabel("Loading your journey")
        .task { await run() }
    }

    private func run() async {
        let start = Date()
        if !reduceMotion {
            withAnimation(.timingCurve(0.15, 0.6, 0.35, 1, duration: waitingSeconds)) {
                progress = waitingProgress
            }
        }
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(start)
            if isReady() || elapsed >= timeout {
                if elapsed < quickLoad {
                    onDone(false)
                    return
                }
                if !reduceMotion {
                    // Run to the end of the line, then hand over to the app.
                    withAnimation(.easeIn(duration: finishSeconds)) { progress = 1 }
                    try? await Task.sleep(for: .seconds(finishSeconds))
                }
                onDone(true)
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}

#Preview {
    LoadingView(isReady: { false }, onDone: { _ in })
}
