import SwiftUI

struct DevMenuView: View {
    @EnvironmentObject private var appState: AppState
    var onDismiss: () -> Void

    @State private var showDesignSystem = false
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            if showDesignSystem {
                designSystemScreen
            } else {
                menuScreen
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Menu

    private var menuScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                }
                Spacer()
                Text("DEV")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Color.clear.frame(width: 52, height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 20)

            Divider()

            menuRow(title: "View design system") {
                withAnimation { showDesignSystem = true }
            }

            Divider().padding(.leading, 24)

            menuRow(title: "Reset app settings", destructive: true) {
                showResetAlert = true
            }

            Spacer()
        }
        .alert("Reset app settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, Reset", role: .destructive) {
                appState.reset()
                onDismiss()
            }
        } message: {
            Text("This will delete all your settings and return you to onboarding.")
        }
    }

    @ViewBuilder
    private func menuRow(title: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(destructive ? .red : .black)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.grey30)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Design System screen

    private var designSystemScreen: some View {
        ZStack(alignment: .topLeading) {
            DesignSystemView()

            Button {
                withAnimation { showDesignSystem = false }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .medium))
                    Text("Menu")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.grey30, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
            }
            .padding(.top, 16)
            .padding(.leading, 24)
            .zIndex(1)
        }
    }
}
