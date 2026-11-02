import SwiftUI

/// First-launch intro (onboarding): two short screens on what TimeToGo is and how it treats
/// your data, then setup. Swipe or tap Next. The card and its button stay put; the background,
/// illustration and text change in place.
struct IntroView: View {
    /// The last screen's button.
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    /// False for the first frame, so the first screen animates in too.
    @State private var hasAppeared = false

    private struct Page {
        let image: String
        /// Artwork size in points (the @3x export ÷ 3).
        let imageSize: CGSize
        /// Gap between the artwork and the card.
        var imageBottom: CGFloat = 0
        /// Where the artwork slides in from.
        let slideFrom: CGFloat
        let background: Color
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(
            image: "intro-1",
            imageSize: CGSize(width: 236, height: 401),
            imageBottom: 13,
            slideFrom: -40,
            background: Color(hex: "C8FEB4"),
            title: "See when to leave the door for your train",
            body: "Add your home and office stations and walking times. We use live TFL API to tell you when to leave."
        ),
        Page(
            image: "intro-2",
            imageSize: CGSize(width: 402, height: 378),
            slideFrom: 40,
            background: Color(hex: "EBE3FF"),
            title: "Your data stays on your phone",
            body: "No account, no tracking: everything is saved on your phone."
        ),
    ]

    /// Figma: the area above the card on the 874pt screen. The artwork scales to fit it.
    private let artAreaHeight: CGFloat = 492
    private let artAreaWidth: CGFloat = 402

    /// Long, soft landing: moves quickly at first, then settles.
    private func enter(duration: Double, delay: Double) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration).delay(delay)
    }
    private let exit = Animation.easeOut(duration: 0.2)

    var body: some View {
        GeometryReader { geo in
            let fullHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom

            VStack(spacing: 0) {
                GeometryReader { area in
                    artwork(in: area.size)
                }
                card(minHeight: min(352, fullHeight * 0.4))
                    .padding(.horizontal, 20)
                    // Figma: 30pt from the screen bottom.
                    .padding(.bottom, max(geo.safeAreaInsets.bottom - 4, 16))
            }
            .ignoresSafeArea()
        }
        .background(pages[page].background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.5), value: page)
        .contentShape(Rectangle())
        .gesture(swipe)
        .onAppear { hasAppeared = true }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20).onEnded { value in
            if value.translation.width < -50, page < pages.count - 1 {
                page += 1
            } else if value.translation.width > 50, page > 0 {
                page -= 1
            }
        }
    }

    private func isShown(_ index: Int) -> Bool {
        hasAppeared && page == index
    }

    // MARK: - Artwork

    private func artwork(in size: CGSize) -> some View {
        let scale = min(size.width / artAreaWidth, size.height / artAreaHeight)

        return ZStack(alignment: .bottom) {
            ForEach(pages.indices, id: \.self) { index in
                let p = pages[index]
                let shown = isShown(index)
                Image(p.image)
                    .resizable()
                    .frame(width: p.imageSize.width * scale, height: p.imageSize.height * scale)
                    .padding(.bottom, p.imageBottom * scale)
                    .opacity(shown ? 1 : 0)
                    .offset(x: shown || reduceMotion ? 0 : p.slideFrom)
                    .animation(shown ? enter(duration: 1.1, delay: 0.1) : exit, value: shown)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .bottom)
    }

    // MARK: - Card

    private func card(minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                dots
                // Both pages stay in the layout so the card keeps its height between them.
                ZStack(alignment: .topLeading) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageText(pages[index], index: index)
                    }
                }
            }

            Spacer(minLength: 24)

            Button {
                if page < pages.count - 1 {
                    page += 1
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Set up my journey")
                    .typography(.h5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .transaction { $0.animation = nil }
        }
        .padding(24)
        // Figma: 352pt; the button sits at the bottom, the text at the top.
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        // On the shape, not the card: a shadow on the card also lands on its text.
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 4.5)
        )
    }

    private func pageText(_ p: Page, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(p.title)
                .typography(.h2)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
                .modifier(TextReveal(shown: isShown(index), delay: 0.15, reduceMotion: reduceMotion, enter: enter, exit: exit))
            Text(p.body)
                .typography(.large)
                .foregroundColor(.grey50)
                .fixedSize(horizontal: false, vertical: true)
                .modifier(TextReveal(shown: isShown(index), delay: 0.27, reduceMotion: reduceMotion, enter: enter, exit: exit))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(page != index)
    }

    /// Current page as a black pill, the other as a grey dot.
    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.black : Color.grey30)
                    .frame(width: i == page ? 20 : 6, height: 6)
            }
        }
        .animation(enter(duration: 0.6, delay: 0), value: page)
        .accessibilityElement()
        .accessibilityLabel("Page \(page + 1) of \(pages.count)")
    }
}

/// Fades text in with a small rise, and straight out.
private struct TextReveal: ViewModifier {
    let shown: Bool
    let delay: Double
    let reduceMotion: Bool
    let enter: (Double, Double) -> Animation
    let exit: Animation

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 10)
            .animation(shown ? enter(0.8, delay) : exit, value: shown)
    }
}

#Preview {
    IntroView(onFinish: {})
}
