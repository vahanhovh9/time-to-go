import SwiftUI

/// First-launch intro (onboarding): three short screens on what TimeToGo is, how it treats
/// your data and how it works, then setup. Swipe or tap Next; Skip goes straight to setup.
struct IntroView: View {
    /// Skip, or the last screen's button.
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page {
        let image: String
        let title: String
        let body: String
        var tip: String? = nil
    }

    private let pages: [Page] = [
        Page(
            image: "intro-1",
            title: "Know when to leave",
            body: "TimeToGo tells you when to leave home so you get to work on time, with the next trains from your station."
        ),
        Page(
            image: "intro-2",
            title: "Your data stays on your phone",
            body: "We only ask for your stations and how long you walk to them. No account, no tracking: everything is saved on your phone.",
            tip: "Tip: time your walk to the station once. Map apps only give an estimate."
        ),
        Page(
            image: "intro-3",
            title: "Set up once, then just open it",
            body: "Choose your stations and walking times. TimeToGo shows when to leave and the live trains at your station, on the way home too."
        ),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index], index: index, screen: geo)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                if page < pages.count - 1 {
                    Button("Skip", action: onFinish)
                        .typography(.large)
                        .foregroundColor(.grey50)
                        .padding(.horizontal, 24)
                        .padding(.top, 15)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                }
            }
        }
        .background(Color(hex: "FFF9C0").ignoresSafeArea())
    }

    // MARK: - Page

    private func pageView(_ p: Page, index: Int, screen: GeometryProxy) -> some View {
        // Figma: the card is 383pt tall on a 874pt screen; shorter phones get a shorter
        // card (never shorter than its content).
        let cardMinHeight = min(383, screen.size.height * 0.44)

        return ZStack(alignment: .top) {
            Color(hex: "FFF9C0")

            // Artwork covers the top of the screen (402×437 in Figma), status bar included.
            Image(p.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            VStack {
                Spacer(minLength: 0)
                card(p, index: index)
                    .frame(minHeight: cardMinHeight)
                    // Its own height only: without this the card's inner spacer stretches it
                    // over the whole screen and hides the illustration.
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    // Figma: 50pt from the screen bottom, i.e. 16pt above the home indicator.
                    .padding(.bottom, screen.safeAreaInsets.bottom + 16)
            }
        }
    }

    private func card(_ p: Page, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                dots(active: index)
                VStack(alignment: .leading, spacing: 16) {
                    Text(p.title)
                        .typography(.h2)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(p.body)
                        .typography(.large)
                        .foregroundColor(.grey50)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let tip = p.tip {
                    Text(tip)
                        .typography(.main)
                        .lineSpacing(1.5)   // Figma: 130% line height at 14pt
                        .foregroundColor(.grey40)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.grey10)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Spacer(minLength: 24)

            Button {
                if index < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { page = index + 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(index < pages.count - 1 ? "Next" : "Set up my journey")
                    .typography(.h5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.grey10, lineWidth: 1))
    }

    /// Current page as a black pill, the others as grey dots.
    private func dots(active: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == active ? Color.black : Color.grey30)
                    .frame(width: i == active ? 20 : 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(active + 1) of \(pages.count)")
    }
}

#Preview {
    IntroView(onFinish: {})
}
