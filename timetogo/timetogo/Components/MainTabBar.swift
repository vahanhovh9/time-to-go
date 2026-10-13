import SwiftUI

/// Bottom navigation: To office / Back home / Settings, with a grey pill behind the selection.
struct MainTabBar: View {
    @Binding var selection: MainTab

    private let items: [(tab: MainTab, icon: String, title: String)] = [
        (.inbound,  "tab-office",   "To office"),
        (.outbound, "tab-home",     "Back home"),
        (.settings, "tab-settings", "Settings")
    ]

    var body: some View {
        HStack {
            ForEach(items, id: \.title) { item in
                Button { selection = item.tab } label: {
                    VStack(spacing: 2) {
                        Image(item.icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text(item.title)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .frame(width: 96, height: 48)
                    .background(selection == item.tab ? Color.grey10 : Color.clear)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == item.tab ? .isSelected : [])

                if item.tab != items.last?.tab { Spacer(minLength: 0) }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)   // 56pt bar (48pt items + 4pt top and bottom)
        .frame(maxWidth: .infinity)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color.grey10).frame(height: 1) }
    }
}

#Preview {
    VStack {
        Spacer()
        MainTabBar(selection: .constant(.inbound))
    }
}
