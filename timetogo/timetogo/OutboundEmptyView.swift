import SwiftUI

struct OutboundEmptyView: View {
    var onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "arrow.left.to.line")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.black)

                Text("Need to be back\nright on time?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)

                Text("Use Outbound to know when you\nshould leave the office.")
                    .font(.system(size: 16, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.grey30)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer()

            CustomButton(title: "Let's go", style: .filled) {
                onGetStarted()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color.yellow
                Image("bg-main")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        )
    }
}

#Preview {
    OutboundEmptyView(onGetStarted: { print("Let's go") })
}
