#if DEBUG
import SwiftUI

struct DevMenuView: View {
    @EnvironmentObject private var appState: AppState
    var onDismiss: () -> Void
    var onClearCache: (() -> Void)? = nil
    var journeyDebugInfo: String? = nil

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
                            .scaledFont(size: 14, weight: .semibold)
                        Text("Back")
                            .scaledFont(size: 14, weight: .semibold)
                    }
                    .foregroundColor(.black)
                }
                Spacer()
                Text("DEV")
                    .scaledFont(size: 16, weight: .bold)
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

            menuRow(title: "Clear commute cache") {
                CommuteCacheManager().clear()
                onClearCache?()
                onDismiss()
            }

            Divider().padding(.leading, 24)

            if let debug = journeyDebugInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Journey diagnostics")
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundColor(Color.grey30)
                    Text(debug)
                        .scaledFont(size: 11, weight: .regular, design: .monospaced)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)

                Divider().padding(.leading, 24)
            } else if let s = appState.settings {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Station NaPTANs (load inbound first)")
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundColor(Color.grey30)
                    Text("Home:   \(s.homeStationId.isEmpty ? "(none)" : s.homeStationId)")
                        .scaledFont(size: 11, weight: .regular, design: .monospaced)
                        .foregroundColor(.black)
                    Text("Office: \(s.officeStationId.isEmpty ? "(none)" : s.officeStationId)")
                        .scaledFont(size: 11, weight: .regular, design: .monospaced)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)

                Divider().padding(.leading, 24)
            }

            menuRow(title: "Reset app settings", destructive: true) {
                showResetAlert = true
            }

            Spacer()
        }
        .alert("Reset app settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, reset", role: .destructive) {
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
                    .scaledFont(size: 16, weight: .medium)
                    .foregroundColor(destructive ? .red : .black)
                Spacer()
                Image(systemName: "chevron.right")
                    .scaledFont(size: 14, weight: .medium)
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
                        .scaledFont(size: 9, weight: .medium)
                    Text("Menu")
                        .scaledFont(size: 10, weight: .medium)
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
#endif
