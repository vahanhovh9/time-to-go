import SwiftUI

/// "Office journey" block: Home → boarding station → alighting station → Office.
/// With line changes (Figma variant "multi") a "1 line change" row sits between the stations.
struct JourneyStops: View {
    var title: String
    var startLabel: String
    var boardingStation: String
    var alightingStation: String
    var endLabel: String
    /// Changes between different lines (Northern → Thameslink); 0 for a direct train.
    var lineChanges: Int = 0
    /// Changes between trains on the same line, e.g. Northern line branches at Camden Town.
    var branchChanges: Int = 0
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
                connector("journey-connector-dashed", size: CGSize(width: 8, height: 12))
                station(boardingStation)
                if lineChanges + branchChanges > 0 {
                    connector("journey-connector-solid-16", size: CGSize(width: 6.5, height: 16))
                    change
                    connector("journey-connector-solid-16", size: CGSize(width: 6.5, height: 16))
                } else {
                    connector("journey-connector-solid-24", size: CGSize(width: 6.5, height: 24))
                }
                station(alightingStation)
                connector("journey-connector-dashed", size: CGSize(width: 8, height: 12))
                endpoint(icon: "journey-pin", iconSize: CGSize(width: 14, height: 17), spacing: 4, label: endLabel)
            }
        }
        .frame(maxWidth: 306, alignment: .leading)
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

    /// The dot sits low in its 12.4×15 frame, which centres it on the name's first line.
    private func station(_ name: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Image("journey-stop")
                .resizable()
                .frame(width: 12.4, height: 15)
            Text(name)
                .typography(.h4)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// "1 line change", "1 branch change", "1 line change, 1 branch change": a hollow dot,
    /// indented a little past the station names.
    private var change: some View {
        HStack(alignment: .top, spacing: 5) {
            Image("journey-change")
                .resizable()
                .frame(width: 12.4, height: 15)
            Text("  " + changeText)
                .scaledFont(size: 16)
                .foregroundColor(.black)
        }
    }

    private var changeText: String {
        func count(_ n: Int, _ kind: String) -> String? {
            n > 0 ? "\(n) \(kind) \(n == 1 ? "change" : "changes")" : nil
        }
        return [count(lineChanges, "line"), count(branchChanges, "branch")]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func connector(_ asset: String, size: CGSize) -> some View {
        Image(asset)
            .resizable()
            .frame(width: size.width, height: size.height)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 32) {
        JourneyStops(
            title: "Office journey",
            startLabel: "Home",
            boardingStation: "Totteridge and Whetstone",
            alightingStation: "Old Street",
            endLabel: "Office"
        )
        JourneyStops(
            title: "Office journey",
            startLabel: "Home",
            boardingStation: "Totteridge and Whetstone",
            alightingStation: "West Hampstead",
            endLabel: "Office",
            lineChanges: 1
        )
    }
    .padding()
    .background(Color(hex: "FFF9C0"))
}
