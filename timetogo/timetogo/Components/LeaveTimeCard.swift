import SwiftUI

/// "LEAVE TODAY AT / 8:02 AM" card with the line-status pill underneath.
struct LeaveTimeCard: View {
    var caption: String
    var time: String
    var status: ServiceStatus?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Text(caption)
                    .typography(.main)
                    .foregroundColor(.grey50)

                Text(time)
                    .scaledFont(size: 56, weight: .bold)
                    .tracking(-2)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

            ServiceStatusPill(status: status)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 9)
    }
}

/// Full-width pill: green for good service, amber for minor delays, red for severe.
struct ServiceStatusPill: View {
    var status: ServiceStatus?

    var body: some View {
        Text(text)
            .typography(.small)
            .foregroundColor(colors.text)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(colors.background)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var text: String {
        switch status {
        case .none:                       return "Checking service…"
        case .goodService:                return "Good service on all lines"
        case .minorDelays(let detail):    return detail.isEmpty ? "Minor delays" : detail
        case .severeDelays(let detail):   return detail.isEmpty ? "Severe delays" : detail
        case .unknown(let detail):        return detail
        }
    }

    private var colors: (background: Color, text: Color) {
        switch status {
        case .goodService:   return (Color(hex: "BBFFA3"), Color(hex: "2F691A"))
        case .minorDelays:   return (Color(hex: "FFE7A3"), Color(hex: "7A5500"))
        case .severeDelays:  return (Color(hex: "FFC4C4"), Color(hex: "8F1D1D"))
        case .unknown, .none: return (.grey10, .grey50)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        LeaveTimeCard(caption: "LEAVE TODAY AT", time: "8:02 AM", status: .goodService)
        LeaveTimeCard(caption: "LEAVE TOMORROW AT", time: "8:10 AM", status: .minorDelays("Northern: Minor Delays"))
        LeaveTimeCard(caption: "LEAVE TODAY AT", time: "--:--", status: .severeDelays("Northern: Severe Delays"))
    }
    .padding(20)
}
