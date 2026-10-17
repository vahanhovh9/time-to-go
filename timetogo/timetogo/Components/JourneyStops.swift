import SwiftUI

/// "Office journey" block: Home → boarding station → alighting station → Office.
struct JourneyStops: View {
    var title: String
    var startLabel: String
    var boardingStation: String
    var alightingStation: String
    var endLabel: String
    /// Opens the full journey. When set, the title gets a chevron and the whole block is tappable.
    var onShowDetails: (() -> Void)? = nil

    var body: some View {
        if let onShowDetails {
            Button(action: onShowDetails) { content }
                .buttonStyle(.plain)
                .accessibilityHint("Shows every step of the journey")
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(title)
                    .typography(.h2)
                    .foregroundColor(.black)
                if onShowDetails != nil {
                    Image(systemName: "chevron.right")
                        .scaledFont(size: 18, weight: .bold)
                        .foregroundColor(.black)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                endpoint(icon: "journey-home", iconSize: CGSize(width: 12, height: 12), spacing: 5, label: startLabel)
                    .frame(minHeight: 16)
                connector("journey-connector-dashed-start", size: CGSize(width: 8, height: 12))
                station(boardingStation)
                connector("journey-connector-solid-24", size: CGSize(width: 6.5, height: 24))
                station(alightingStation)
                connector("journey-connector-dashed-end", size: CGSize(width: 9, height: 12))
                endpoint(icon: "journey-pin", iconSize: CGSize(width: 14, height: 17), spacing: 4, label: endLabel)
            }
        }
        .frame(maxWidth: 294, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func endpoint(icon: String, iconSize: CGSize, spacing: CGFloat, label: String) -> some View {
        HStack(spacing: spacing) {
            Image(icon)
                .resizable()
                .frame(width: iconSize.width, height: iconSize.height)
            Text(label)
                .scaledFont(size: 16)
                .tracking(-0.5)
                .foregroundColor(.black)
                .lineLimit(1)
        }
    }

    private func station(_ name: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Image("journey-stop")
                .resizable()
                .frame(width: 12.4, height: 12.4)
                // Centres the dot on the first line of the name, as in Figma.
                .padding(.top, 3)
            Text(name)
                .typography(.h4)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func connector(_ asset: String, size: CGSize) -> some View {
        Image(asset)
            .resizable()
            .frame(width: size.width, height: size.height)
    }
}

#Preview {
    JourneyStops(
        title: "Office journey",
        startLabel: "Home",
        boardingStation: "Totteridge and Whetstone",
        alightingStation: "Old Street",
        endLabel: "Office"
    )
    .padding()
    .background(Color(hex: "FFF9C0"))
}
