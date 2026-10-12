import SwiftUI

/// "Office journey" block: Home → boarding station → alighting station → Office.
struct JourneyStops: View {
    var title: String
    var startLabel: String
    var boardingStation: String
    var alightingStation: String
    var endLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .tracking(-0.5)
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 0) {
                endpoint(icon: "journey-home", iconSize: CGSize(width: 12, height: 12), label: startLabel)
                connector("journey-connector-dashed-8", height: 8)
                station(boardingStation)
                connector("journey-connector-solid-24", height: 24)
                station(alightingStation)
                connector("journey-connector-dashed-7", height: 7)
                endpoint(icon: "journey-pin", iconSize: CGSize(width: 11.4, height: 14.5), label: endLabel)
            }
        }
        .frame(width: 188, alignment: .leading)
    }

    private func endpoint(icon: String, iconSize: CGSize, label: String) -> some View {
        HStack(spacing: 5) {
            Image(icon)
                .resizable()
                .frame(width: iconSize.width, height: iconSize.height)
                .frame(width: 12.4)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.black)
        }
        .frame(height: 16)
    }

    private func station(_ name: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image("journey-stop")
                .resizable()
                .frame(width: 12.4, height: 12.4)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1.5 }
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 16)
    }

    private func connector(_ asset: String, height: CGFloat) -> some View {
        Image(asset)
            .resizable()
            .frame(width: 6.5, height: height)
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
